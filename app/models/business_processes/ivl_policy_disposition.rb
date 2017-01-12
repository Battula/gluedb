module BusinessProcesses
  class IvlPolicyDisposition
    include Handlers::EnrollmentEventXmlHelper

    attr_reader :enrollment_event_cv, :policy_cv
    def initialize(e_event_cv, p_cv)
      @enrollment_event_cv = e_event_cv
      @policy_cv = p_cv
    end

    def change_kind
      @change_kind ||= extract_enrollment_action(enrollment_event_cv)
    end

    def renewal_candidates
      @renewal_candidates ||= begin
                                plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
                                return [] if subscriber_person.nil?
                                subscriber_person.policies.select do |pol|
                                  ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
                                end
                              end
    end

    def policy_action
      current_action = extract_enrollment_action(enrollment_event_cv)
      # If they say it's a passive renewal, it's a passive renewal
      return current_action if is_ivl_passive_renewal?
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
      return "urn:openhbx:terms:v1:enrollment#initial" if subscriber_person.nil?
      # Determine and provide correct action here
      if competing_policies.any?
        competing_policies.each do |c_pol|
          if c_pol.plan.carrier_id == plan.carrier_id
            return "urn:openhbx:terms:v1:enrollment#change_product"
          end
        end
      end
      if renewal_candidates.any?
        renewal_candidates.each do |rc|
          if plan.carrier_id == rc.plan.carrier_id
            return "urn:openhbx:terms:v1:enrollment#active_renew"
          end
        end
      end
      "urn:openhbx:terms:v1:enrollment#initial"
    end

    def members_changed?
      return false if (!renewal_candidates.any? && !competing_policies.any?)
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
      return false if subscriber_person.nil?
      pol_member_ids = extract_policy_member_ids(policy_cv).map { |mi| mi.strip.split("#").last }.compact
      if renewal_candidates.any?
        renewal_candidates.each do |rc|
          if plan.carrier_id == rc.plan.carrier_id
            rc_member_ids = rc.enrollees.map(&:m_id).uniq
            new_member_ids = pol_member_ids - rc_member_ids
            drop_member_ids = rc_member_ids - pol_member_ids
            if new_member_ids.any? || drop_member_ids.any?
              return true
            end
          end
        end
      end
      if competing_policies.any?
        competing_policies.each do |rc|
          if plan.carrier_id == rc.plan.carrier_id
            rc_member_ids = rc.enrollees.map(&:m_id).uniq
            new_member_ids = pol_member_ids - rc_member_ids
            drop_member_ids = rc_member_ids - pol_member_ids
            if new_member_ids.any? || drop_member_ids.any?
              return true
            end
          end
        end
      end
      false
    end

    def terminations
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
      return [] if subscriber_person.nil?
      terms = []
      if renewal_candidates.any?
        renewal_candidates.each do |rc|
          # Add a termination for the old carrier for each switch
          if plan.carrier_id != rc.plan.carrier_id
            terms << BusinessProcess::EnrollmentTermination.new(rc.eg_id, subscriber_start - 1.day, c_pol.active_member_ids)
          end  
        end
      end
      if competing_policies.any?
        competing_policies.each do |c_pol|
          # Terminate the enrollment - transmit ONLY if different carrier
          if c_pol.coverage_period.begin < subscriber_start
            term = ::BusinessProcesses::EnrollmentTermination.new(c_pol.eg_id, subscriber_start - 1.day, c_pol.active_member_ids)
            if plan.carrier_id == c_pol.plan.carrier_id
              term.transmit = false
            end
            terms << term
          end
        end
      end
      terms
    end

    def cancels
      return [] if !competing_policies.any?
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
      return [] if subscriber_person.nil?
      cancel_pols = []
      if competing_policies.any?
        competing_policies.each do |c_pol|
          # cancel the enrollment - transmit ONLY if different carrier
          if c_pol.coverage_period.begin == subscriber_start
            cancellation = ::BusinessProcesses::EnrollmentCancellation.new(c_pol.eg_id, c_pol.active_member_ids)
            if plan.carrier_id == c_pol.plan.carrier_id
              cancellation.transmit = false
            end
            cancel_pols << cancellation
          end
        end
      end
      cancel_pols
    end

    def competing_policies
      @competing_policies ||= competing_ivl_coverage
    end

    def bogus_ivl_renewal?
      return false unless is_ivl_passive_renewal?
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
      return false if subscriber_person.nil?
      !renewal_candidates.any?
    end

    def is_ivl_active_renewal?
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#active_renew"
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    def is_ivl_passive_renewal?
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#auto_renew",
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    protected

    def extract_policy_details
      @policy_details ||=
        begin
          subscriber_enrollee = extract_subscriber(policy_cv)
          subscriber_id = extract_member_id(subscriber_enrollee)
          subscriber_start = extract_enrollee_start(subscriber_enrollee)
          plan = extract_plan(policy_cv)
          coverage_type = plan.coverage_type
          subscriber_person = Person.find_by_member_id(subscriber_id)
          [plan, subscriber_person, subscriber_id, subscriber_start]
        end
    end

    def competing_ivl_coverage
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
      return [] if subscriber_person.nil?
      subscriber_person.policies.select do |pol|
        overlapping_policy?(pol, plan, subscriber_id, subscriber_start)
      end
    end

    def overlapping_policy?(pol, plan, subscriber_id, subscriber_start)
      return false if pol.canceled?
      return false if pol.subscriber.blank?
      return false if (pol.subscriber.m_id != subscriber_id)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false unless (plan.year == pol.plan.year)
      return false unless pol.employer_id.blank?
      return true if pol.subscriber.coverage_end.blank?
      !(pol.subscriber.coverage_end < subscriber_start)
    end

    def ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
      return false if pol.is_shop?
      return false unless (pol.plan.year == plan.year - 1)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false if pol.canceled?
      return false if pol.terminated?
      (pol.coverage_period.end == (subscriber_start - 1.day))
    end
  end
end

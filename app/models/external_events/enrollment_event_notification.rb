module ExternalEvents
  class EnrollmentEventNotification
    attr_reader :timestamp
    attr_reader :event_xml
    attr_reader :message_tag
    attr_reader :errors
    attr_reader :event_responder
    attr_reader :headers

    include Handlers::EnrollmentEventXmlHelper
    include Comparable

    def initialize(e_responder, m_tag, t_stamp, e_xml, headers)
      @business_process_history = []
      @errors = ActiveModel::Errors.new(self)
      @headers = headers
      @errors = []
      @timestamp = t_stamp
      @droppable = false
      @bogus_termination = false
      @bogus_renewal_termination = false
      @event_responder = e_responder
      @message_tag = m_tag
      @event_xml = e_xml
    end

    def hash
      bucket_id.hash
    end

    def bucket_id 
      [subscriber_id, coverage_type, employer_hbx_id]
    end

    def mark_for_drop!
      @droppable = true
    end

    def drop_if_bogus_term!
      return false unless @bogus_termination
      event_responder.broadcast_response(
        "error",
        "unmatched_termination",
        "422",
        event_xml,
        headers
      )
      event_responder.ack_message(message_tag)
      instance_variables.each do |iv|
        instance_variable_set(iv, nil)
      end
      true
    end

    def drop_if_marked!
      return false unless @droppable
      event_responder.broadcast_ok_response(
        "enrollment_reduced",
        event_xml,
        headers
      )
      event_responder.ack_message(message_tag)
      # GC hint by nilling out references
      instance_variables.each do |iv|
        instance_variable_set(iv, nil)
      end
      true
    end

    def check_for_bogus_renewal_term_against(other)
      return nil if other.is_termination?
      return nil unless is_termination?
      return nil unless (subscriber_end == (other.subscriber_start - 1.day))
      return nil unless (other.active_year.to_i == active_year.to_i - 1)
      @bogus_renewal_termination = true
    end

    def drop_if_bogus_renewal_term!
      return false unless @bogus_renewal_termination
      event_responder.broadcast_ok_response(
        "renewal_termination_reduced",
        event_xml,
        headers
      )
      event_responder.ack_message(message_tag)
      # GC hint by nilling out references
      instance_variables.each do |iv|
        instance_variable_set(iv, nil)
      end
      true
    end

    def check_for_bogus_term_against(others)
      return unless is_termination?
      others.each do |other|
        if (other.hbx_enrollment_id == hbx_enrollment_id) && other.is_coverage_starter?
          @bogus_termination = false
          return 
        end
      end
      @bogus_termination = existing_policy.nil?
    end

    def check_and_mark_duplication_against(other)
      if duplicates?(other)
        self.mark_for_drop!
        other.mark_for_drop!
      end
    end

    def duplicates?(other)
      return false unless other.bucket_id == bucket_id
      return false unless other.active_year == active_year
      return false unless other.hbx_enrollment_id == hbx_enrollment_id
      (other.is_coverage_starter? && self.is_cancel?) ||
        (other.is_cancel? && self.is_coverage_starter?)
    end

    def is_coverage_starter?
      [
        "urn:openhbx:terms:v1:enrollment#initial",
        "urn:openhbx:terms:v1:enrollment#auto_renew",
        "urn:openhbx:terms:v1:enrollment#active_renew"
      ].include?(enrollment_action)
    end

    def <=>(other)
      if other.hbx_enrollment_id == hbx_enrollment_id
        case [other.is_termination?, is_termination?]
        when [true, false]
          -1
        when [false, true]
          1
        else
          0
        end
      elsif other.active_year != active_year
        active_year.to_i <=> other.active_year.to_i
      elsif subscriber_start != other.subscriber_start
        subscriber_start <=> other.subscriber_start
      else
        case [subscriber_end.nil?, other.subscriber_end.nil?]
        when [true, true]
          0
        when [false, true]
          1
        when [true, false]
          -1
        else
          subscriber_end <=> other.subscriber_end
        end
      end
    end

    def subscriber_start
      @subscriber_start ||= extract_enrollee_start(subscriber)
    end

    def subscriber_end
      @subscriber_end ||= extract_enrollee_end(subscriber)
    end

    def is_passive_renewal?
      (enrollment_action == "urn:openhbx:terms:v1:enrollment#auto_renew")
    end

    def is_termination?
      (enrollment_action == "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
    end

    def is_cancel?
      return false unless (enrollment_action == "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
      extract_enrollee_start(subscriber) == extract_enrollee_end(subscriber)
    end

    def enrollment_action
      @enrollment_action ||= extract_enrollment_action(enrollment_event_xml)
    end

    def enrollment_event_xml
      @enrollment_event_xml ||= enrollment_event_cv_for(event_xml)
    end

    def policy_cv
      @policy_cv ||= extract_policy(enrollment_event_xml)
    end

    def hbx_enrollment_id
      @hbx_enrollment_id ||= Maybe.new(policy_cv).id.value
    end

    def subscriber
      @subscriber ||= extract_subscriber(policy_cv)
    end

    def subscriber_id
      @subscriber_id ||= extract_member_id(subscriber)
    end

    def active_year
      @active_year ||= extract_active_year(policy_cv)
    end

    def is_adjacent_to?(other)
      return false unless active_year == other.active_year
      case [is_termination?, other.is_termination?]
      when [true, true]
        false
      when [false, false]
        false
      when [false, true]
        false
      else
        (self.subscriber_end == other.subscriber_start - 1.day) || (self.is_cancel? && (subscriber_start == other.subscriber_start))
      end
    end

    def employer_hbx_id
      @employer_hbx_id ||= begin
                           if determine_market(enrollment_event_xml) == "individual"
                             nil
                           else
                             Maybe.new(policy_cv).policy_enrollment.shop_market.employer_link.id.strip.split("#").last.value
                           end
                         end
    end

    def coverage_type
      @coverage_type ||= Maybe.new(policy_cv).policy_enrollment.plan.is_dental_only.value
    end

    def update_business_process_history(entry)
      @business_process_history << entry
    end


    # Errors stuff for ActiveModel::Errors
    def read_attribute_for_validation(attr)
      send(attr)
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    def existing_policy
      @existing_policy ||= Policy.where(eg_id: hbx_enrollment_id).first
    end

    private

    def initialize_clone(other)
      @headers = other.headers.clone
      @timestamp = other.timestamp.clone
      @event_xml = other.event_xml.clone
      @message_tag = other.message_tag.clone
      @event_responder = other.event_responder
      @errors = other.errors.clone
    end
  end
end

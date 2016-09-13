module Services
  class PolicyPublisher
    def self.publish_cancel(p_id)
      ::Workflow::CancelPolicy.new.call(p_id)
    end

    def self.publish(q_reason_uri, p_id)
      policy = Policy.where(:id => p_id).first
      p_action = policy_action(policy)
      reason = (p_action.downcase == "initial_enrollment") ? "initial_enrollment" : p_action.downcase
      operation = (p_action.downcase == "initial_enrollment") ? "add" : "change"
      v_destination = (p_action.downcase == "initial_enrollment") ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
      routing_key = case reason
      when "renewal"
        "policy.renewal"
      when "initial_enrollment"
        "policy.initial_enrollment"
      else
        "policy.maintenance"
      end
      xml_body = serialize(policy, operation, reason)
      with_channel do |channel|
        channel.direct(ExchangeInformation.request_exchange, :durable => true).publish(xml_body, {
          :routing_key => routing_key,
          :reply_to => v_destination,
          :headers => {
            :file_name => "#{p_id}.xml",
            :submitted_by => "trey.evans@dc.gov",
            :vocabulary_destination => v_destination
          }
        })
      end
    end

    def self.serialize(pol, operation, reason)
      member_ids = pol.enrollees.map(&:m_id)
      serializer = CanonicalVocabulary::MaintenanceSerializer.new(
        pol,
        operation,
        reason,
        member_ids,
        member_ids
      )
      serializer.serialize
    end

    def self.with_channel
      session = AmqpConnectionProvider.start_connection
      chan = session.create_channel
      chan.prefetch(1)
      yield chan
      session.close
    end

    def self.policy_action(policy)
      subscriber = policy.subscriber
      coverage_start = subscriber.coverage_start
      sub_person = subscriber.person
      policies_to_check = sub_person.policies.reject do |pol|
        pol.canceled? || (pol.id == policy.id) || (pol.coverage_type.downcase != policy.coverage_type.downcase) ||
          (pol.employer_id.blank? != policy.employer_id.blank?)
      end
      initial_enrollment =  ::PolicyInteractions::InitialEnrollment.new
      renewal = ::PolicyInteractions::Renewal.new
      plan_change = ::PolicyInteractions::PlanChange.new

      if initial_enrollment.qualifies?(policies_to_check, policy)
        "initial_enrollment"
      elsif renewal.qualifies?(policies_to_check, policy)
        "renewal"
      elsif plan_change.qualifies?(policies_to_check, policy)
        "plan_change"
      end
    end
  end
end

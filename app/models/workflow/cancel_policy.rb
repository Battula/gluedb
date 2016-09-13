module Workflow
  class CancelPolicy
    include Workflow::TransmitPolicy

    def call(p_id)
      policy = Policy.where(:id => p_id).first
      routing_key = "policy.cancel"
      v_destination = "hbx.maintenance_messages"
      operation = "cancel"
      reason = "termination_of_benefits"

      xml_body = serialize(policy, operation, reason)
      with_channel do |channel|
        channel.direct(ExchangeInformation.request_exchange, :durable => true).publish(xml_body, {
          :routing_key => routing_key,
          :reply_to => v_destination,
          :headers => {
            :file_name => "#{p_id}.xml",
            :submitted_by => "trey.evans@dchbx.info",
            :vocabulary_destination => v_destination
          }
        })
      end
    end
  end
end

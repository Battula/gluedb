module Services
  class CvPublisher
    attr_reader :submitted_by
     
    def initialize(submitter = "trey.evans@dc.gov")
      @submitted_by = submitter
    end

    def publish(is_maintenance, file_name, data)
      return if Rails.env.test?
#      tag = is_maintenance ? "hbx.maintenance_messages" : "hbx.enrollment_messages"
      tag = "#{ExchangeInformation.hbx_id}.#{ExchangeInformation.environment}.q.legacy_carrier_encoder"
      conn = AmqpConnectionProvider.start_connection
      ch = conn.create_channel
      ch.confirm_select
      x = ch.default_exchange

      x.publish(
        data,
        {
          :routing_key => "hbx.vocab_validator",
          :reply_to => tag,
          :headers => {
            :file_name => file_name,
            :submitted_by => submitted_by
          }
        }
      )
      ch.wait_for_confirms
      conn.close
    end

  end
end

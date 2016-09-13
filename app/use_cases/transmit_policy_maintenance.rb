class TransmitPolicyMaintenance
  def execute(request)
      xml = CanonicalVocabulary::MaintenanceSerializer.new(
      Policy.find(request[:policy_id]),
        request[:operation],
        request[:reason],
        request[:affected_enrollee_ids],
        request[:include_enrollee_ids]
      ).serialize
      submit_cv('maintenance', xml, request[:current_user])
  end

  private

  def submit_cv(cv_kind, data, current_user)
    return if Rails.env.test?
    tag = (cv_kind.to_s.downcase == "maintenance") ? "hbx.maintenance_messages" : "hbx.enrollment_messages"
    conn = AmqpConnectionProvider.start_connection
    ch = conn.create_channel
    x = ch.default_exchange

    x.publish(
      data,
      :routing_key => "hbx.vocab_validator",
      :reply_to => tag,
      :headers => {
        :file_name => "#{SecureRandom.uuid.gsub('-','')}.xml",
        :submitted_by => current_user
      }
    )
    conn.close
  end
end

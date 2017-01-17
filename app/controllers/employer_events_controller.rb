class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvent.order_by(event_time: 1)
  end

  def publish
    connection = AmqpConnectionProvider.start_connection
    EmployerEvent.with_digest_payloads do |payload|
      Amqp::ConfirmedPublisher.with_confirmed_channel(connection) do |chan|
        chan.default_exchange.publish(
          payload,
          {routing_key: drop_queue_name}
        )
      end
    end
    conn.close
    redirect_to employer_events_path
  end

  def download
    zip_path = EmployerEvent.get_all_digests

    begin
      send_data File.read(zip_path), :filename => "carrier_events.zip"
    ensure
      FileUtils.rm_f(zip_path)
    end
  end

  def drop_queue_name
    ec = ExchangeInformation
    "#{ec.hbx_id}.#{ec.environment}.q.hbx_enterprise.employer_digest_drop_listener"
  end
end

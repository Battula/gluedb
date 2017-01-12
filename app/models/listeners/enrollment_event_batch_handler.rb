module Listeners
  class EnrollmentEventBatchHandler < Amqp::Client
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.enrollment_event_batch_handler"
    end

    def process
      events = []
      responder = ::ExternalEvents::EventResponder.new(
        "application.gluedb.enrollment_event_batch_handler",
        channel
      )
      di, props, payload = queue.pop({:manual_ack => true})
      while (di != nil) do
        headers = props.headers || {}
        event_message = ExternalEvents::EnrollmentEventNotification.new(
          responder,
          di.delivery_tag,
          extract_timestamp(props),
          payload,
          headers
        )
        events << event_message
        di, props, payload = queue.pop({:manual_ack => true})
      end
      results = EnrollmentEventProcessingClient.new.call(events)
    end

   def self.create_queues(chan)
      q = chan.queue(
        self.queue_name,
        {
          :durable => true,
          :arguments => {
            "x-dead-letter-exchange" => (self.queue_name + "-retry")
          }
        }
      )
      retry_q = chan.queue(
        (self.queue_name + "-retry"),
        {
          :durable => true,
          :arguments => {
            "x-dead-letter-exchange" => (self.queue_name + "-requeue"),
            "x-message-ttl" => 1000
          }
        }
      )
      retry_exchange = chan.fanout(
        (self.queue_name + "-retry")
      )
      requeue_exchange = chan.fanout(
        (self.queue_name + "-requeue")
      )
      retry_q.bind(retry_exchange, {:routing_key => ""})
      q.bind(requeue_exchange, {:routing_key => ""})
      q
    end

    def self.create_bindings(chan, q)
      ec = ExchangeInformation
      event_topic_exchange_name = "#{ec.hbx_id}.#{ec.environment}.e.topic.events"
      event_topic_exchange = chan.topic(event_topic_exchange_name, {:durable => true})
      # Replace with correct bindings for enrollment events
      # q.bind(event_topic_exchange, {:routing_key => "info.events.employer.#"})
    end

    def self.configure!
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      q = create_queues(chan)
      create_bindings(chan, q)
      conn.close
    end

    def self.run
      conn = AmqpConnectionProvider.start_connection
      chan = conn.create_channel
      q = create_queues(chan)
      self.new(chan, q).process
      conn.close
    end
  end
end

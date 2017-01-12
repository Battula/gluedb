class EnrollmentEventProcessingClient < Middleware::Builder
  def initialize
    super do |b|
      b.use Handlers::EnrollmentEventReduceHandler
      b.use Handlers::EnrollmentEventEnrichHandler
      b.use Handlers::EnrollmentEventPersistHandler
      b.use Handlers::EnrollmentEventPublishHandler
    end
  end

  def stack
    super
  end
end

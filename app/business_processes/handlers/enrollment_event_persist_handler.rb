module Handlers
  class EnrollmentEventPersistHandler < ::Handlers::Base

    # Handle the persistence operations for an enrollment action,
    # updating the objects in glue accordingly
    # ::EnrollmentAction::Base -> ::EnrollmentAction::Base
    def call(context)
      persisted_actions = context.select(&:persist)
      persisted_actions.map do |pa|
        super(pa)
      end
    end
  end
end

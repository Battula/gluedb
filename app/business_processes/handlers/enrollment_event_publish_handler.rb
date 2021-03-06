module Handlers
  class EnrollmentEventPublishHandler < ::Handlers::Base

    # Handle the publishing operations for an enrollment action
    # ::EnrollmentAction::Base -> ::EnrollmentAction::Base
    def call(context)
      context.publish
    end
  end
end

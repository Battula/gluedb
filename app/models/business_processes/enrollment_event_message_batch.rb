module BusinessProcesses
  class EnrollmentEventMessageBatch
    attr_accessor :enrollment_event_messages
    attr_accessor :enrollment_event_errors
    attr_accessor :business_process_history

    def initialize(e_event_msgs)
      @enrollment_event_messages = e_event_msgs
      @errors = ::BusinessProcesses::EnrollmentEventErrors.new
      @business_process_history = []
    end

    private

    def initialize_clone(other)
      @errors = other.errors.clone
      if other.business_process_history.present?
        @business_process_history = other.business_process_history.clone
      end
    end
  end
end

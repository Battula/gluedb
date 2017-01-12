require "rails_helper"

describe Handlers::EnrollmentEventEnrichHandler, "given:
- an enrollment termination event
- that event has no corresponding database record
- there is no other corresponding enrollment event notification
" do
  let(:next_step) { double }

  subject { Handlers::EnrollmentEventEnrichHandler.new(next_step) }

  it "drops and logs the bogus termination event"
end

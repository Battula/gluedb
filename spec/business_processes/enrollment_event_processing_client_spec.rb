require "rails_helper"

describe EnrollmentEventProcessingClient do
  it "can be composed inside of other processes" do
    expect {
      Middleware::Builder.new do |b|
        b.use subject.stack
      end
    }.not_to raise_error
  end

  it "has steps in the stack" do
    expect(subject.stack).not_to be_empty
  end
end

require "rails_helper"

describe HandleEnrollmentEvent::ProcessDependentAdd do
  it "passes the lint test for all its components existing" do
    expect(subject).not_to eq nil
  end
end

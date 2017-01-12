require "rails_helper"

describe Handlers::EnrollmentEventReduceHandler, "given:
- 3 notifications
- 2 of which should reduce"  do
  
  let(:non_duplicate_notification) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 1, :drop_if_marked! => false, :bucket_id => 5) }
  let(:duplicate_notification_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => true) }
  let(:duplicate_notification_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => true) }
  let(:notifications) { [duplicate_notification_1, duplicate_notification_2, non_duplicate_notification] }

  let(:next_step) { double("The next step in the pipeline") }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(next_step).to receive(:call).with([non_duplicate_notification])
    allow(duplicate_notification_1).to receive(:check_and_mark_duplication_against).with(duplicate_notification_2)
    allow(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
  end

  it "sends along 1 bucket with the non-reduced enrollment notification" do
    expect(next_step).to receive(:call).with([non_duplicate_notification])
    subject.call(notifications)
  end

  it "updates the business process history of the non-duplicate enrollment" do
    expect(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end

end

describe Handlers::EnrollmentEventReduceHandler, "given:
- 3 notifications
- 2 of which should be bucketed together"  do
  
  let(:non_duplicate_notification) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 1, :drop_if_marked! => false, :bucket_id => 5) }
  let(:same_bucket_notification_1) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => false, :bucket_id => 4) }
  let(:same_bucket_notification_2) { instance_double(::ExternalEvents::EnrollmentEventNotification, :hash => 3, :drop_if_marked! => false, :bucket_id => 4) }
  let(:notifications) { [same_bucket_notification_1, same_bucket_notification_2, non_duplicate_notification] }

  let(:next_step) { double("The next step in the pipeline") }

  subject { Handlers::EnrollmentEventReduceHandler.new(next_step) }

  before :each do
    allow(next_step).to receive(:call).with([non_duplicate_notification])
    allow(next_step).to receive(:call).with([same_bucket_notification_1, same_bucket_notification_2])
    allow(same_bucket_notification_1).to receive(:check_and_mark_duplication_against).with(same_bucket_notification_2)
    allow(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    allow(same_bucket_notification_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    allow(same_bucket_notification_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
  end

  it "sends along a bucket with the single enrollment notification" do
    expect(next_step).to receive(:call).with([non_duplicate_notification])
    subject.call(notifications)
  end

  it "sends along a bucket with the same-bucket enrollment notifications" do
    expect(next_step).to receive(:call).with([same_bucket_notification_1, same_bucket_notification_2])
    subject.call(notifications)
  end

  it "updates the business process history of the single bucket enrollment" do
    expect(non_duplicate_notification).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end

  it "updates the business process history of the first group bucket enrollment" do
    expect(same_bucket_notification_1).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end

  it "updates the business process history of the second group bucket enrollment" do
    expect(same_bucket_notification_2).to receive(:update_business_process_history).with("Handlers::EnrollmentEventReduceHandler")
    subject.call(notifications)
  end
end

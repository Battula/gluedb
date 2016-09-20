require "rails_helper"

RSpec.shared_examples "a listener recording the event outcome" do |message_properties, message_body|
  it "broadcasts an event with #{message_properties}" do
    expect(event_broadcaster).to receive(:broadcast).with(send(message_properties), message_body)
    subject.on_message(di, props, body)
  end
end

RSpec.shared_examples "a listener consuming the message" do
  it "acknowledges the message on the channel" do
    expect(channel).to receive(:ack).with(delivery_tag, false)
    subject.on_message(di, props, body)
  end
end

describe Listeners::IndividualEventListener do
  let(:timestamp) { Time.mktime(2008,11,13,0,0,0) }
  let(:connection) { double }
  let(:channel) { double(:connection => connection) }
  let(:subject) { Listeners::IndividualEventListener.new(channel, nil) }
  let(:individual_id) { "an individual id" }
  let(:props) { double(:headers => { :individual_id => individual_id }) }
  let(:body) { "" }
  let(:delivery_tag) { "an amqp delivery tag" }
  let(:di) { double(:delivery_tag => delivery_tag) }
  let(:event_broadcaster) { instance_double("::Amqp::EventBroadcaster") }

  before :each do
    allow(Time).to receive(:now).and_return(timestamp)
    allow(::Amqp::EventBroadcaster).to receive(:new).with(connection).and_return(event_broadcaster)
  end

  describe "contacting the 'callback' service to get the full individual resource" do
    let(:other_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.unknown_error",
      :headers => {
        :return_status => "500",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    let(:not_found_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.resource_not_found",
      :headers => {
        :return_status => "404",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    let(:timeout_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.resource_timeout",
      :headers => {
        :return_status => "503",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    context "if the callback request times out" do
      before :each do
        allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["503", nil])
        allow(channel).to receive(:reject).with(delivery_tag, true)
        allow(event_broadcaster).to receive(:broadcast).with(timeout_error_properties, "")
      end

      it "requeues the message" do
        expect(channel).to receive(:reject).with(delivery_tag, true)
        subject.on_message(di, props, body)
      end

      it_should_behave_like "a listener recording the event outcome", :timeout_error_properties, ""
    end

    context "if the resource does not exist" do
      before :each do
        allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["404", nil])
        allow(channel).to receive(:ack).with(delivery_tag, false)
        allow(event_broadcaster).to receive(:broadcast).with(not_found_error_properties, "")
      end

      it_should_behave_like "a listener consuming the message"
      it_should_behave_like "a listener recording the event outcome", :not_found_error_properties, ""
    end

    context "when there is an unspecified error" do
      before :each do
        allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["500", "some string about something"])
        allow(event_broadcaster).to receive(:broadcast).with(other_error_properties, "some string about something")
        allow(channel).to receive(:ack).with(delivery_tag, false)
      end
      it_should_behave_like "a listener consuming the message"
      it_should_behave_like "a listener recording the event outcome", :other_error_properties, "some string about something"
    end
  end

  describe "given a new individual" do
    let(:new_individual_resource) {
      double(:to_s => "a body value for the resource")
    }

    let(:individual_creation_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.individual_created",
      :headers => {
        :return_status => "422",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    let(:individual_created_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_created",
      :headers => {
        :return_status => "200",
        :individual_id => individual_id, 
        :submitted_timestamp => timestamp
      }
    } }

    let(:individual_change_set) {
      instance_double("::ChangeSets::IndividualChangeSet", :individual_exists? => false, :create_individual_resource => creation_result, :full_error_messages => full_error_messages)
    }

    let(:full_error_messages) { ["a", "list of", "error messages"] }

    before :each do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["200", new_individual_resource])
      allow(ChangeSets::IndividualChangeSet).to receive(:new).with(new_individual_resource).and_return(individual_change_set)
    end

    context "given a valid individual" do
      let(:creation_result) { true }

      before :each do
        allow(channel).to receive(:ack).with(delivery_tag, false)
        allow(event_broadcaster).to receive(:broadcast).with(individual_created_properties, "a body value for the resource")
      end

      it_should_behave_like "a listener consuming the message"
      it_should_behave_like "a listener recording the event outcome", :individual_created_properties, "a body value for the resource"
    end

    context "given an invalid individual" do
      let(:creation_result) { false }

      before :each do
        allow(channel).to receive(:ack).with(delivery_tag, false)
        allow(event_broadcaster).to receive(:broadcast).with(individual_creation_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
      end

      it_should_behave_like "a listener consuming the message"

      it "broadcasts an event with the validation errors for the individual" do
        expect(event_broadcaster).to receive(:broadcast).with(individual_creation_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
        subject.on_message(di, props, body)
      end
    end
  end

  describe "given an individual which already exists" do
    let(:new_individual_resource) {
      double(:to_s => "a body value for the resource")
    }

    let(:individual_change_set) {
      instance_double("::ChangeSets::IndividualChangeSet", :individual_exists? => true, :any_changes? => changed_value, :multiple_changes? => multiple_changes_result, :dob_changed? => dob_change_result, :full_error_messages => full_error_messages, :dropping_subscriber_home_address? => drop_subscriber_address_result)
    }

    let(:individual_updated_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_updated",
      :headers => {
        :return_status => "200",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    let(:individual_update_error_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.individual_updated",
      :headers => {
        :return_status => "422",
        :individual_id => individual_id, 
        :submitted_timestamp => timestamp
      }
    } }

    let(:individual_drop_subscriber_address_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.subscriber_home_address_required",
      :headers => {
        :return_status => "422",
        :individual_id => individual_id, 
        :submitted_timestamp => timestamp
      }
    } }

    let(:individual_dob_changed_properties) { {
      :routing_key => "error.application.gluedb.individual_update_event_listener.individual_dob_changed",
      :headers => {
        :return_status => "501",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    let(:individual_unchanged_properties) { {
      :routing_key => "info.application.gluedb.individual_update_event_listener.individual_updated",
      :headers => {
        :return_status => "304",
        :individual_id => individual_id,
        :submitted_timestamp => timestamp
      }
    } }

    let(:multiple_changes_result) { false}
    let(:dob_change_result) { false}
    let(:full_error_messages) { ["a", "list of", "error messages"] }
    let(:drop_subscriber_address_result) { false }

    before :each do
      allow(RemoteResources::IndividualResource).to receive(:retrieve).with(subject, individual_id).and_return(["200", new_individual_resource])
      allow(ChangeSets::IndividualChangeSet).to receive(:new).with(new_individual_resource).and_return(individual_change_set)
    end

    describe "with no changes" do
      let(:changed_value) { false }
      
      before(:each) do
        allow(channel).to receive(:ack).with(delivery_tag, false)
        allow(event_broadcaster).to receive(:broadcast).with(individual_unchanged_properties, "a body value for the resource")
      end

      it_should_behave_like "a listener consuming the message"

      it_should_behave_like "a listener recording the event outcome", :individual_unchanged_properties, "a body value for the resource"
    end

    describe "with a single change" do
      let(:multiple_changes_result) { false}
      let(:changed_value) { true }

      describe "and the change is for a subscriber and has no home address" do
        let(:drop_subscriber_address_result) { true }

        before(:each) do
          allow(channel).to receive(:ack).with(delivery_tag, false)
          allow(event_broadcaster).to receive(:broadcast).with(individual_drop_subscriber_address_properties, "a body value for the resource")
        end

        it_should_behave_like "a listener consuming the message"
        it_should_behave_like "a listener recording the event outcome", :individual_drop_subscriber_address_properties, "a body value for the resource"
      end

      describe "and that change is to dob" do
        let(:dob_change_result) { true }

        before(:each) do
          allow(channel).to receive(:ack).with(delivery_tag, false)
          allow(event_broadcaster).to receive(:broadcast).with(individual_dob_changed_properties, "a body value for the resource")
        end

        it_should_behave_like "a listener consuming the message"
        it_should_behave_like "a listener recording the event outcome", :individual_dob_changed_properties, "a body value for the resource"
      end

      describe "and that change is not to dob" do
        let(:dob_change_result) { false }

        describe "with an invalid update" do
          before(:each) do
            allow(channel).to receive(:ack).with(delivery_tag, false)
            allow(event_broadcaster).to receive(:broadcast).with(individual_update_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
            allow(individual_change_set).to receive(:process_first_edi_change).and_return(false)
          end

          it_should_behave_like "a listener consuming the message"

          it "broadcasts a message with the validation errors" do
            expect(event_broadcaster).to receive(:broadcast).with(individual_update_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
            subject.on_message(di, props, body)
          end
        end

        describe "with a valid update" do
          before(:each) do
            allow(channel).to receive(:ack).with(delivery_tag, false)
            allow(event_broadcaster).to receive(:broadcast).with(individual_updated_properties, "a body value for the resource")
            allow(individual_change_set).to receive(:process_first_edi_change).and_return(true)
          end

          it_should_behave_like "a listener consuming the message"
          it_should_behave_like "a listener recording the event outcome", :individual_updated_properties, "a body value for the resource"
        end
      end
    end

    describe "with multiple changes" do
      let(:multiple_changes_result) { true }
      let(:changed_value) { true }

      describe "and the change is for a subscriber and has no home address" do
        let(:drop_subscriber_address_result) { true }

        before(:each) do
          allow(channel).to receive(:ack).with(delivery_tag, false)
          allow(event_broadcaster).to receive(:broadcast).with(individual_drop_subscriber_address_properties, "a body value for the resource")
        end

        it_should_behave_like "a listener consuming the message"
        it_should_behave_like "a listener recording the event outcome", :individual_drop_subscriber_address_properties, "a body value for the resource"
      end

      describe "with an invalid update" do
        before :each do
          allow(channel).to receive(:ack).with(delivery_tag, false)
          allow(individual_change_set).to receive(:process_first_edi_change).and_return(false)
          allow(event_broadcaster).to receive(:broadcast).with(individual_update_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
        end

        it_should_behave_like "a listener consuming the message"

        it "broadcasts the validation errors" do
          expect(event_broadcaster).to receive(:broadcast).with(individual_update_error_properties, JSON.dump({:resource => "a body value for the resource", :errors => full_error_messages}))
          subject.on_message(di, props, body)
        end
      end

      describe "with a valid update" do
        let(:individual_updated_properties) { {
          :routing_key => "info.application.gluedb.individual_update_event_listener.individual_updated_partially",
          :headers => {
            :return_status => "200",
            :individual_id => individual_id,
            :submitted_timestamp => timestamp
          }
        } }

        before :each do
          allow(channel).to receive(:reject).with(delivery_tag, true)
          allow(individual_change_set).to receive(:process_first_edi_change).and_return(true)
          allow(event_broadcaster).to receive(:broadcast).with(individual_updated_properties, "a body value for the resource")
        end

        it "rejects the message" do
          expect(channel).to receive(:reject).with(delivery_tag, true)
          subject.on_message(di, props, body)
        end

        it_should_behave_like "a listener recording the event outcome", :individual_updated_properties, "a body value for the resource"

      end
    end
  end
end

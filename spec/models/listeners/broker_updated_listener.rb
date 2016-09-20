require 'rails_helper'

describe Listeners::BrokerUpdatedListener do
  let(:broker) { double }
  let(:broker_hbx_id) { "a broker npn" }
  let(:message_body) { "" }
  let(:message_properties) { double(:headers => message_headers) }
  let(:message_headers) { { :broker_id => broker_hbx_id } }
  let(:connection) { double }
  let(:channel) { double(:connection => connection) }
  let(:queue) { double }
  let(:message_tag) { "a message tag" }
  let(:delivery_info) { double(:delivery_tag => message_tag) }
  let(:expected_broker_properties) { {
    :name_first => "Jane",
    :name_last => "Curtin",
    :name_middle => "Phred",
    :name_pfx => "Dr",
    :name_sfx => "III",
    :npn => "2068981",
    :b_type => "broker"
  } }
  let(:mock_requestor) { double }
  let(:r_di) { double }
  let(:error_channel) { double(:close =>  nil) }
  let(:mock_event_exchange_name) { "mock event exchange name" }
  let(:mock_event_exchange) { double }
  let(:time_provider) { double( :now => 1 ) }

  subject { Listeners::BrokerUpdatedListener.new(channel, queue) }

  before :each do
    allow(error_channel).to receive(:fanout).with(mock_event_exchange_name, {:durable => true}).and_return(mock_event_exchange)
    allow(ExchangeInformation).to receive(:event_publish_exchange).and_return(mock_event_exchange_name)
    allow(Amqp::Requestor).to receive(:new).with(connection).and_return(mock_requestor)
    allow(Broker).to receive(:by_npn).with(broker_hbx_id).and_return(matching_brokers)
    allow(mock_requestor).to receive(:request).with(
      {:headers => { :broker_id => broker_hbx_id }, :routing_key => "resource.broker"}, "", 10
    ).and_return([r_di, r_props, resource_body])
    allow(channel).to receive(:acknowledge).with("a message tag", false)
  end

  describe "given a broker which doesn't exist" do
    let(:resource_body) { File.read(File.join(Rails.root, "spec/data/resources/broker.xml")) }
    let(:r_props) { double(:headers => {}) }
    let(:matching_brokers) { [] }
    let(:mock_new_broker) { double(:save => valid_broker_value) }

    before :each do
      allow(Broker).to receive(:new).with(expected_broker_properties).and_return(mock_new_broker)
    end

    describe "with valid new broker info" do
      let(:valid_broker_value) { true }

      it "should create that broker" do
        allow(connection).to receive(:create_channel).and_return(error_channel)
        expect(mock_event_exchange).to receive(:publish).with("", {:routing_key=>"info.application.gluedb.broker_update_listener.broker_created", :timestamp=>1, :headers=>{:broker_id=> broker_hbx_id }})
        expect(channel).to receive(:acknowledge).with(message_tag,false)
        subject.on_message(delivery_info, message_properties, message_body, time_provider)
      end
    end

    describe "with invalid new broker info" do
      let(:mock_errors) { double(:full_messages => ["an error message"]) }
      let(:valid_broker_value) { false }
      let(:expected_error_payload) {
        JSON.dump({
          :broker_attributes => expected_broker_properties,
          :errors =>  ["an error message"]
        })
      }

      before(:each) do
        allow(connection).to receive(:create_channel).and_return(error_channel)
        allow(mock_new_broker).to receive(:errors).and_return(mock_errors)
      end

      it "should not create that broker and log an error" do
        expect(mock_event_exchange).to receive(:publish).with(expected_error_payload, {:routing_key=>"error.application.gluedb.broker_update_listener.invalid_broker_creation", :timestamp=>1, :headers=>{:broker_id=> broker_hbx_id }})
        expect(channel).to receive(:acknowledge).with(message_tag,false)
        subject.on_message(delivery_info, message_properties, message_body, time_provider)
      end
    end
  end

  describe "given a broker which exists" do
    let(:resource_body) { File.read(File.join(Rails.root, "spec/data/resources/broker.xml")) }
    let(:r_props) { double(:headers => {}) }
    let(:matching_brokers) { [broker] }
    describe "with valid update information" do
      before :each do
        allow(broker).to receive(:update_attributes).with(expected_broker_properties).and_return(true)
      end

      it "should update that broker" do
        allow(connection).to receive(:create_channel).and_return(error_channel)
        expect(mock_event_exchange).to receive(:publish).with("", {:routing_key=>"info.application.gluedb.broker_update_listener.broker_updated", :timestamp=>1, :headers=>{:broker_id=> broker_hbx_id }})
        expect(channel).to receive(:acknowledge).with(message_tag,false)
        subject.on_message(delivery_info, message_properties, message_body, time_provider)
      end
    end

    describe "with invalid update information" do
      let(:mock_errors) { double(:full_messages => ["an error message"]) }
      let(:expected_error_payload) {
        JSON.dump({
          :broker_attributes => expected_broker_properties,
          :errors =>  ["an error message"]
        })
      }
      before :each do
        allow(broker).to receive(:update_attributes).with(expected_broker_properties).and_return(false)
        allow(connection).to receive(:create_channel).and_return(error_channel)
        allow(broker).to receive(:errors).and_return(mock_errors)
      end

      it "should not update that broker and log an error" do
        expect(mock_event_exchange).to receive(:publish).with(expected_error_payload, {:routing_key=>"error.application.gluedb.broker_update_listener.invalid_broker_update", :timestamp=>1, :headers=>{:broker_id=> broker_hbx_id }})
        expect(channel).to receive(:acknowledge).with(message_tag,false)
        subject.on_message(delivery_info, message_properties, message_body, time_provider)
      end
    end
  end

  describe "with a requestor that times out" do
    let(:resource_body) { nil }
    let(:r_props) { nil }
    let(:matching_brokers) { [] }
    it "should re-queue the message for retry" do
      allow(connection).to receive(:create_channel).and_return(error_channel)
      expect(mock_event_exchange).to receive(:publish).with("", {:routing_key=>"error.application.gluedb.broker_update_listener.resource_lookup_timeout", :timestamp=>1, :headers=>{:broker_id=> broker_hbx_id }})
      expect(channel).to receive(:nack).with(message_tag,false,true)
      subject.on_message(delivery_info, message_properties, message_body, time_provider)
    end
  end

  describe "with a requestor gets a 404" do
    let(:resource_body) { "" }
    let(:r_props) { double(:headers => {:return_status => "404"}) }
    let(:matching_brokers) { [] }

    it "should log the missing resource error to the bus, and ack the message" do
      allow(connection).to receive(:create_channel).and_return(error_channel)
      expect(mock_event_exchange).to receive(:publish).with("", {:routing_key=>"error.application.gluedb.broker_update_listener.non_existant_resource", :timestamp=>1, :headers=>{:broker_id=> broker_hbx_id }})
      expect(channel).to receive(:acknowledge).with(message_tag,false)
      subject.on_message(delivery_info, message_properties, message_body, time_provider)
    end
  end
end

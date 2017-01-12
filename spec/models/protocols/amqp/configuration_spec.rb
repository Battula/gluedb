require "spec_helper"

module PAConfigurationMocking
  class CFInstanceMock
    def initialize(chan)
      @channel = chan
      @started = false
    end

    def start
      @started = true
    end

    def create_channel
      raise "Connection not started!" unless @started
      @channel
    end
  end

  class CFWrapper
    def initialize(chan_double, ext_con_string)
      @channel = chan_double
      @expected_connection_string = ext_con_string
    end

    def new(c_uri)
        raise "Connection initialized with wrong URL" unless c_uri == @expected_connection_string
        CFInstanceMock.new(@channel)
    end
  end

end

describe Protocols::Amqp::Configuration do
  subject { Protocols::Amqp::Configuration }

  it "should have the connection url" do
    expect(subject.connection_url).not_to be_nil
  end

  it "should provide a connection when instructed" do
    channel_mock = double
    connection_object_mock = PAConfigurationMocking::CFWrapper.new(
      channel_mock,
      subject.connection_url
    )
    expect(subject.connection(connection_object_mock)).to eq(channel_mock)
  end

=begin
  it "should provide a good default connection when asked", :integration => "amqp" do
    channel = subject.connection
    expect(channel).to be_kind_of(Bunny::Channel)
  end
=end
end

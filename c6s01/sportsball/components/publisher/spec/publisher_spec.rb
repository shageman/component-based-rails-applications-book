
require "spec_helper"

describe Publisher do
  class PublisherTestHarness
    include Publisher
  end

  class SomeMessageSubscriber
    attr_accessor :some_message_called, :hello_called
    def some_message
      @some_message_called = true
    end

    def hello
      @hello_called = true
    end
  end

  class HelloSubscriber
    attr_accessor :hello_called
    def hello
      @hello_called = true
    end
  end

  subject do
    PublisherTestHarness.new
  end

  before do
    @subscriber1 = SomeMessageSubscriber.new
    @subscriber2 = HelloSubscriber.new
  end

  it "will do nothing if there are no subscribers" do
    expect {
      subject.publish(:some_message)
    }.not_to raise_exception
  end

  it "will not send a message to a subscriber that does not have the method" do
    subject.add_subscriber(@subscriber2)
    subject.publish(:some_message)
    expect(@subscriber2.hello_called).to eq(nil)
  end

  it "will call the messages method on the subscriber if it exists" do
    subject.add_subscriber(@subscriber1)
    subject.publish(:some_message)
    expect(@subscriber1.some_message_called).to eq(true)
  end

  it "will send messages to multiple subscribers" do
    subject.add_subscriber(@subscriber1)
    subject.add_subscriber(@subscriber2)
    subject.publish(:hello)
    expect(@subscriber1.hello_called).to eq(true)
    expect(@subscriber1.hello_called).to eq(true)
  end

  it "causes problems to send the wrong number of params" do
    subject.add_subscriber(@subscriber1)
    expect {
      subject.publish(:some_message, "erroneous_parameter")
    }.to raise_exception(ArgumentError)
  end
end


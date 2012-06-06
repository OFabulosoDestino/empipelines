require 'empipelines'

module EmPipelines
  class StubQueue
    attr_accessor :name
    def subscribe(ack, &code)
      @code = code
    end

    def publish(header, payload)
      @code.call(header,  payload)
    end
  end

  describe AmqpEventSource do
    let (:em) { mock('eventmachine') }
    let (:logging) { mock('logging') }
    let (:services) { { logging: logging } }

    it 'wraps each AMQP message and send to listeners' do
      json_payload = '{"key":"value"}'
      queue = StubQueue.new
      queue.name = "this.is.some.queue"
      event_type = "NuclearWar"
      header = stub('header')

      received_messages = []

      amqp_source = AmqpEventSource.new(em, queue, event_type, services)
      amqp_source.on_event { |e| received_messages << e }
      amqp_source.start!

      queue.publish(header, json_payload)

      received_messages.size.should eql(1)
      received_messages.first[:origin].should ==(queue.name)
      received_messages.first[:payload].should ==({:key => "value"})
      received_messages.first[:event].should ==(event_type)
      received_messages.first[:started_at].should_not be_nil
    end

    it 'acknowledges consumed messages' do
      queue = StubQueue.new
      header = mock('header')

      header.should_receive(:ack)

      amqp_source = AmqpEventSource.new(em, queue, 'event type', services)
      amqp_source.on_event { |e| e.consumed! }
      amqp_source.start!

      queue.publish(header, '{"key":"value"}')
    end

    it 'marks message as broken if cannot be parsed' do
      queue = StubQueue.new
      header = mock('header')

      header.should_receive(:reject).with({:requeue => false})
      services[:logging].should_receive(:inform_exception!)

      amqp_source = AmqpEventSource.new(em, queue, 'event type', services)
      amqp_source.on_event { raise 'should never happen' }
      amqp_source.start!

      queue.publish(header, 'some junk')
    end

    it 'rejects broken messages with no requeue' do
      queue = StubQueue.new
      header = mock('header')

      header.should_receive(:reject).with({:requeue => false})

      amqp_source = AmqpEventSource.new(em, queue, 'event type', services)
      amqp_source.on_event { |e| e.broken! }
      amqp_source.start!

      queue.publish(header, '{"key":"value"}')
    end

    it 'rejects rejected messages with requeue' do
      queue = StubQueue.new
      header = mock('header')

      header.should_receive(:reject).with({:requeue => true})

      amqp_source = AmqpEventSource.new(em, queue, 'event type', services)
      amqp_source.on_event { |e| e.rejected! }
      amqp_source.start!

      queue.publish(header, '{"key":"value"}')
    end
  end
end

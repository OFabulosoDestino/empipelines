require 'empipelines/amqp_event_source'

module EmPipelines
  class StubQueue
    def subscribe(&code)
      @code = code
    end

    def publish(header, payload)
      @code.call(header,  payload)
    end
  end
  
  describe AmqpEventSource do
    it "adds payload, time and event type to message and sends to listener" do
      json_payload = '{"key":"value"}'
      queue = StubQueue.new
      event_type = "NuclearWar"
      header = stub('header')

      received_messages = []
      
      amqp_source = AmqpEventSource.new(queue, event_type)
      amqp_source.on_event { |e| received_messages << e }
      amqp_source.start!

      queue.publish(header, json_payload)

      received_messages.size.should eql(1)
      received_messages.first[:header].should ==(header)
      received_messages.first[:payload].should ==({:key => "value"})
      received_messages.first[:event].should ==(event_type)
      received_messages.first[:started_at].should_not be_nil
    end
  end
end

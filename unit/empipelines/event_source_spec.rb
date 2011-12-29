require 'empipelines/event_source'

module EmPipelines
  class StubEventSource < EventSource
    def something_happenend!(message)
      event_handler.call(message)
    end

    def finish!
      finished_handler.call(self)
    end
  end

  describe EventSource do
    let(:source) { StubEventSource.new }

    context 'defining callbacks' do
      it 'supports blocks or procs as event handlers'
      
      it 'supports multiple callbacks for a single event'
    end

    context 'calling callbacks' do
      it 'calls the event callback when an message is to be processed' do
        message = stub('message')
        received = []
        source.on_event { |a| received << a }
        source.something_happenend!(message)
        received.should==([message])
      end

      it 'calls the finished callback when all events were processed' do
        message = stub('message')
        received = []
        source.on_finished { |a| received << a }
        source.finish!
        received.should==([source])
      end
    end

    context 'flow control' do
    end
  end
end

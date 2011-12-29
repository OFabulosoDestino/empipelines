require 'empipelines/event_source'

module EmPipelines
  class StubEventSource < EventSource
    def event_now!(message)
      event!(message)
    end

    def finish_now!
      finished!
    end
  end

  describe EventSource do
    let(:source) { StubEventSource.new }

    context 'defining callbacks' do
      it 'supports multiple callbacks for a single event'
    end

    context 'calling callbacks' do
      it 'calls the event callback when an message is to be processed' do
        message = stub('message')
        received = []
        source.on_event { |a| received << a }
        source.event_now!(message)
        received.should==([message])
      end

      it 'calls the finished callback when all events were processed' do
        message = stub('message')
        received = []
        source.on_finished { |a| received << a }
        source.finish_now!
        received.should==([source])
      end

      it 'does not do anything if no callbacks' do
        StubEventSource.new.event_now!({})
        StubEventSource.new.finish_now!
      end
    end

    context 'flow control' do
    end
  end
end

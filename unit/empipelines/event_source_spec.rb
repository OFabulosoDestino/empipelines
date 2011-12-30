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
      it 'supports multiple callbacks for a single event'do
        message1 = {:a => 1}
        message2 = {:b => 2}

        received = []
        finished = []

        source = StubEventSource.new
        source.on_event {|m| received << [1, m]}
        source.on_event {|m| received << [2, m]}
        source.on_event {|m| received << [3, m]}

        source.on_finished {|s| finished << [10, s]}
        source.on_finished {|s| finished << [20, s]}
        source.on_finished {|s| finished << [30, s]}

        source.event_now!(message1)
        source.event_now!(message2)

        source.finish_now!

        received.should ==([
                            [1, message1],
                            [2, message1],
                            [3, message1],
                            [1, message2],
                            [2, message2],
                            [3, message2]
                           ])

        finished.should ==([
                            [10, source],
                            [20, source],
                            [30, source]
                           ])
      end

      it 'lets a list of handlers to be defined' do
        message1 = {:a => 1}
        message2 = {:b => 2}

        received = []
        finished = []

        source = StubEventSource.new
        source.on_event([lambda{|m| received << [1, m]}, lambda{|m| received << [2, m]}])
        source.on_event {|m| received << [3, m]}

        source.on_finished([lambda{|s| finished << [10, s]}, lambda{|s| finished << [20, s]}])
        source.on_finished {|s| finished << [30, s]}

        source.event_now!(message1)

        source.finish_now!

        received.should ==([[1, message1],[2, message1],[3, message1]])
        finished.should ==([[10, source],[20, source],[30, source]])
      end
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

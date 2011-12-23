require 'empipelines/aggregated_event_source'

module EmPipelines
  class EventSourceStub
    include EventHandlers

    def event!(contents)
      raise 'not started' unless @started
      event_handler.call(contents) if event_handler
    end

    def finish!
      raise 'not started' unless @started
      finished_handler.call([:this, :should, :not, :be, :used])
    end

    def start!
      @started = true
    end
  end

  describe AggregatedEventSource do

    let (:em) do
      em = mock('eventmachine')
      em.stub(:next_tick).and_yield
      em
    end

    let (:list_name) { "list of stuff"  }

    it 'sends each sends messages from all sources, as they happen, to listeners' do
      source1, source2, source3 = EventSourceStub.new, EventSourceStub.new, EventSourceStub.new

      aggregated = AggregatedEventSource.new(em, source1, source2, source3)

      expected = (0..4).map{ |i| stub("Message #{i}") }
      received = []
      aggregated.on_event { |m| received << m}

      aggregated.start!

      source1.event! expected[0]
      source2.event! expected[1]
      source2.event! expected[2]
      source3.event! expected[3]
      source1.event! expected[4]

      received.should ==(expected)
    end

    it 'calls the finished handler when all sources finished' do
      sources = [EventSourceStub.new, EventSourceStub.new, EventSourceStub.new]

      aggregated = AggregatedEventSource.new(em, sources)

      has_finished = [false]
      aggregated.on_finished do |s|
        s.should ==(aggregated)
        has_finished[0] = true
      end

      aggregated.start!
      sources[2].finish!
      sources[1].finish!
      sources[0].finish!

      has_finished.first.should be_true
    end

    it 'does not call the finished handler if a source is still going' do
      sources = [EventSourceStub.new, EventSourceStub.new, EventSourceStub.new]

      aggregated = AggregatedEventSource.new(em, sources)

      aggregated.on_finished do |s|
        raise 'should never happen'
      end

      aggregated.start!
      sources[2].finish!
      sources[0].finish!
    end
  end
end

require 'empipelines/event_source'

module EmPipelines
  class AggregatedEventSource <  EventSource

    def initialize(em, *event_sources)
      @em, @sources = em, event_sources.flatten
    end

    def start!
      finished = 0
      @sources.each do |s|
        s.on_event(event_handler)

        s.on_finished do |*ignored|
          finished += 1
          finished! if finished == @sources.size
        end

        @em.next_tick { s.start! }
      end
    end
  end
end

require 'empipelines/event_handlers'

module EmPipelines
  class AggregatedEventSource
    include EventHandlers
    
    def initialize(em, *event_sources)
      @em, @sources = em, event_sources.flatten
    end

    def start!
      finished = 0
      @sources.each do |s|
        s.on_event(event_handler)
        
        s.on_finished do |*ignored|
          finished += 1
          finished_handler.call(self) if finished == @sources.size
        end
        @em.next_tick { s.start! }
      end      
    end
  end
end

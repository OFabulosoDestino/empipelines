module Pipelines
  class PeriodicEventSource
    def initialize(em, interval_in_secs, &event_sourcing_code)
      @em, @interval_in_secs, @event_sourcing_code = em, interval_in_secs, event_sourcing_code
    end

    def start!
      event_sourcing_code = @event_sourcing_code

      @em.add_periodic_timer(@interval_in_secs) do
        tick!
      end
    end

    def on_event(&handler)
      @handler = handler
    end

    def tick!      
      event = @event_sourcing_code.call
      @handler.call(event) if event
    end
  end
end

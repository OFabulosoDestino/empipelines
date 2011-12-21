module EmPipelines
  class PeriodicEventSource
    def initialize(em, name, interval_in_secs, &event_sourcing_code)
      @em                  = em
      @name                = name
      @interval_in_secs    = interval_in_secs
      @event_sourcing_code = event_sourcing_code 
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
      
      @handler.call(Message.new(:payload => event, :origin => @name)) if event
    end
  end
end

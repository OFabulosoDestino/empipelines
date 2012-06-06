require 'empipelines/event_source'

module EmPipelines
  class PeriodicEventSource < EventSource
    #on finish!!!!
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

    def tick!
      event = @event_sourcing_code.call

      event!(Message.new(:payload => event, :origin => @name)) if event
    end
  end
end

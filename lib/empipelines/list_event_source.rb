module EmPipelines
  class ListEventSource
    def initialize(events)
      @events = events
    end

    def start!
      @events.each do |e|
        @handler.call({:payload => e})
      end
    end

    def on_event(&handler)
      @handler = handler
    end
  end
end

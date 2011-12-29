module EmPipelines
  class ListEventSource < EventSource
    def initialize(name, events)
      @origin = name
      @events = events
    end

    def start!
      @events.each do |e|
        event!(Message.new({:origin => @origin, :payload => e}))
      end
      finished!
    end
  end
end

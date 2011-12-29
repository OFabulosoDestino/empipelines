module EmPipelines
  class EventSource
    def on_event(event_handler=nil, &block)
      @event_handler = block_given? ? block : event_handler
    end

    def on_finished(batch_finished_handler=nil, &block)
      @finished_handler = block_given? ? block : batch_finished_handler
    end

    protected
    def finished_handler
      @finished_handler
    end

    def event_handler
      @event_handler
    end
  end
end

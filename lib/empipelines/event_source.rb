module EmPipelines
  class EventSource
    def on_event(handler=nil, &block)
      add_handlers!(event_handler, (handler || block))
    end

    def on_finished(handler=nil, &block)
      add_handlers!(finished_handler, (handler || block))
    end

    protected
    def event_handler
      @event_handler ||= []
      @event_handler
    end

    def finished_handler
      @finished_handler ||= []
      @finished_handler
    end
    
    def finished!
      finished_handler.each{ |h| h.call(self) }
    end

    def event!(msg)
      event_handler.each{ |h| h.call(msg) }
    end

    private
    def add_handlers!(handler_list, new_handlers)
      to_add = new_handlers.is_a?(Enumerable) ? new_handlers : [new_handlers]
      to_add.each { |h| handler_list << h  }
    end
  end
end

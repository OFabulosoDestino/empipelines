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
      if event_handler.size == 1 then
        event_handler.first.call(msg)
      else
        copies = a_copy_per_handler(msg)
        event_handler.each do |h|
          h.call(copies.pop)
        end
      end
    end

    private
    def a_copy_per_handler(msg)
        msg_copies = event_handler.map { |x| msg.copy }

        verify_copies = lambda do |m|
          if msg_copies.all?(&:processed?) then
            if msg_copies.any? { |m| m.state == :broken } then
              msg.broken!
            elsif msg_copies.any? { |m| m.state == :rejected } then
              msg.rejected!
            else
              msg.consumed!
            end
          end
        end

        msg_copies.each do |copy|
          copy.on_consumed(verify_copies)
          copy.on_rejected(verify_copies)
          copy.on_broken(verify_copies)
        end

        msg_copies.clone
    end

    def add_handlers!(handler_list, new_handlers)
      to_add = new_handlers.is_a?(Enumerable) ? new_handlers : [new_handlers]
      to_add.each { |h| handler_list << h  }
    end
  end
end

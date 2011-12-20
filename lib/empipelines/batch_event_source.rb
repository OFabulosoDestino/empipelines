require 'empipelines/event_handlers'

module EmPipelines
  class BatchEventSource
    include EventHandlers
    
    def initialize(em, events)
      @em, @events = em, events
    end

    def start!
      @finalised = []
      check_if_finished

      message_finished = lambda do |m|
        @finalised << m
        check_if_finished
      end

      @events.each do |e|
        message = Message.new({:payload => e})

        message.on_rejected_broken(message_finished)
        message.on_rejected(message_finished)
        message.on_consumed(message_finished)

        event_handler.call(message)
      end
    end

    private
    def check_if_finished
      finished = (@finalised.size == @events.size)

      if finished and finished_handler
        @em.next_tick { finished_handler.call(@finalised) }
      end
    end
  end
end

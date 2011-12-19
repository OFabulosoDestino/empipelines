module Pipelines
  class BatchEventSource
    def initialize(em, events)
      @em, @events = em, events
    end

    def on_event(&handler)
      @handler = handler
    end

    def on_batch_finished(&batch_finished_handler)
      @batch_finished_handler = batch_finished_handler
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

        @handler.call(message)
      end
    end

    private
    def check_if_finished
      finished = (@finalised.size == @events.size)

      if finished and @batch_finished_handler
        @em.next_tick { @batch_finished_handler.call(@finalised) }
      end
    end
  end
end

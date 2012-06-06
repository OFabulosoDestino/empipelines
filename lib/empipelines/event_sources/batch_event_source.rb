require 'empipelines/event_source'

module EmPipelines
  class BatchEventSource < EventSource

    def initialize(em, list_name, events)
      @num_finalised = 0
      @em, @list_name, @events = em, list_name, events
    end

    def start!
      @finalised = []
      check_if_finished

      message_finished = lambda do |m|
        @num_finalised += 1
        check_if_finished
      end

      @events.each do |e|
        message = Message.new({
                                :payload => e,
                                :origin => @list_name
                              })

        message.on_broken(message_finished)
        message.on_rejected(message_finished)
        message.on_consumed(message_finished)

        event!(message)
      end
    end

    private
    def check_if_finished
      #TODO: can we make this not be based on size?
      #it makes it harder to have streams as event sources (i.e. ranges).
      #this class should only rely on Enumerable methods.
      finished! if (@num_finalised == @events.size)
    end
  end
end

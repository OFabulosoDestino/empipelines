require 'empipelines/event_source'

require 'json'

module EmPipelines
  #this must have a on_finished!
  class AmqpEventSource < EventSource

    def initialize(em, queue, event_name)
      @em, @queue, @event_name = em, queue, event_name
    end

    def on_event(&handler)
      @handler = handler
    end

    def start!
      @queue.subscribe do |header, json_payload|
        message = Message.new ({
                                 :header     => header,
                                 :origin     => @queue.name,
                                 :payload    => JSON.parse(json_payload),
                                 :event      => @event_name,
                                 :started_at => Time.now.to_i
                                })
        @handler.call(message)
      end
    end
  end
end

require 'json'

module Pipelines
  class AmqpEventSource
    def initialize(queue, event_name)
      @queue, @event_name = queue, event_name
    end

    def on_event(&handler)
      @handler = handler
    end

    def start!
      @queue.subscribe do |header, json_payload|
        message = Message.new ({
                                :header     => header,
                                :payload    => JSON.parse(json_payload),
                                :event      => @event_name,
                                :started_at => Time.now.to_i
                                })
        @handler.call(message)
      end
    end
  end
end

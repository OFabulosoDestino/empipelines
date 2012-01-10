require 'empipelines/event_source'
require 'empipelines/message'

require 'json'

module EmPipelines
  #this must have a on_finished!
  class AmqpEventSource < EventSource

    def initialize(em, queue, event_name)
      @em, @queue, @event_name = em, queue, event_name
    end

    def start!
      @queue.subscribe(:ack => true) do |header, json_payload|
        message = Message.new({
                                :origin     => @queue.name,
                                :payload    => JSON.parse(json_payload),
                                :event      => @event_name,
                                :started_at => Time.now.to_i
                              })
        message.on_consumed { |m| header.ack }
        message.on_broken   { |m| header.reject(:requeue => true) }
        message.on_rejected { |m| header.reject(:requeue => true) }
        event!(message)
      end
    end
  end
end

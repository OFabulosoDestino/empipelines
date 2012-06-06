require 'empipelines/event_source'

require 'json'

module EmPipelines
  #this must have a on_finished!
  class AmqpEventSource < EventSource

    def initialize(em, queue, event_name, monitoring)
      @em, @queue, @event_name, @monitoring = em, queue, event_name, monitoring
    end

    def start!
      @queue.subscribe(:ack => true) do |header, json_payload|
        begin
          message = Message.new({
                                  :origin     => @queue.name,
                                  :payload    => JSON.parse(json_payload),
                                  :event      => @event_name,
                                  :started_at => Time.now.to_i
                                })
          message.on_consumed { |m| header.ack }
          message.on_broken   { |m| header.reject(:requeue => false) }
          message.on_rejected { |m| header.reject(:requeue => true) }
          event!(message)
        rescue => exc
          @monitoring.inform_exception!(exc, self, 'removing message from queue')
          header.reject(:requeue => false)
        end
      end
    end
  end
end

require 'empipelines/event_source'

require 'json'

module EmPipelines
  #this must have a on_finished!
  class AmqpEventSource < EventSource
    # TODO: why is amqp the only EventSource
    # that needs a `monitoring` on initialize?
    def initialize(em, queue, event_name, services)
      @em, @queue, @event_name, @services = em, queue, event_name, services
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
          @services[:monitoring].inform_exception!(exc, self, 'removing message from queue')
          header.reject(:requeue => false)
        end
      end
    end
  end
end

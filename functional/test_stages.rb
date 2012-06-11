require "amqp"
require "empipelines"

ExchangeName  = "empipelines.build"
QueueName     = "empipelines.build.queue"

module TestStages
  def self.setup_queues(exchange_name=ExchangeName, queue_name=QueueName)
    connection = AMQP.connect()
    channel = AMQP::Channel.new(connection)
    channel.prefetch(1)

    exchange = channel.direct(exchange_name, :durable => true)
    queue = channel.queue(queue_name, :durable => true)
    queue.bind(exchange)
    queue.purge
    [exchange, queue]
  end

  module EmRunner
    def with_em_timeout(timeout, &test_body)
      EM.run do
        EM.add_timer(timeout) do
          EM.stop
          raise "################### Test timed-out! ################### "
        end

        test_body.call
      end
    end
  end

  # Later, we'll need to inspect `processed` as part of test assertions
  module CallerTestingOverride
    def call(message, &callback)
      processed << [@id, message.co_id]
      super
    end
  end

  class PassthroughStage < EmPipelines::Stage
    module Caller
      def call(message, &callback)
        callback.call(message.merge!({}))
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class RetryOscillator < EmPipelines::Stage
    module Caller
      def call(message, &callback)
        @flip = !@flip || false
        message.rejected! if @flip
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class ShouldNotBeReachedStage < EmPipelines::Stage
    module Caller
      def call(message, &callback)
        raise "should not be reached but got #{message}!"
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class ConsumeStage < EmPipelines::Stage
    module Caller
      def call(message, &callback)
        message.consumed!
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class RejectStage < EmPipelines::Stage
    module Caller
      def call(message, &callback)
        message.rejected!
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class BrokenMessageStage < EmPipelines::Stage
    module Caller
      def call(message, &callback)
        message.broken!
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class ValidatesPresenceStage < EmPipelines::Stage
    extend EmPipelines::MessageValidity

    validates_presence_of_keys :a, :b, :c, :d

    module Caller
      def call(message, &callback)
        message.broken! unless validate!(message)

        callback.call(message)
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class ValidatesNumericalityStage < EmPipelines::Stage
    extend EmPipelines::MessageValidity

    validates_numericality_of_keys :c

    module Caller
      def call(message, &callback)
        message.broken! unless validate!(message)

        callback.call(message)
      end
    end

    include Caller
    include CallerTestingOverride
  end

  class ValidatesTemporalityStage < EmPipelines::Stage
    extend EmPipelines::MessageValidity

    validates_temporality_of_keys :b

    module Caller
      def call(message, &callback)
        message.broken! unless validate!(message)

        callback.call(message)
      end
    end

    include Caller
    include CallerTestingOverride
  end
end

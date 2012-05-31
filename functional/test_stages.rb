require "empipelines/message_validity"
require "empipelines/stage"

module TestStages
  class Monitoring
    def initialize(output = false)
      @output = output
    end

    def inform(txt)
      puts "#{Time.now.usec}  INFO: #{txt}" if @output
    end

    def debug(txt)
      puts "#{Time.now.usec} DEBUG: #{txt}" if @output
    end

    def inform_exception!(exc, origin, extra = nil)
      puts "#{Time.now.usec} ERROR: #{exc} at #{origin} - #{extra}" if @output
    end
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

  module SomeStage
    @@last_id = 0
    attr_accessor :monitoring

    def initialize(monitoring)
      @id = "module ##{(@@last_id)}"
      @@last_id += 1
      super
    end

    def call(message, &callback)
      processed << [@id, message.co_id]
      process(message, callback)
    end
  end

  class PassthroughStage < EmPipelines::Stage
    include SomeStage

    def process(message, callback)
      callback.call(message.merge!({}))
    end
  end

  class RetryOscillator < EmPipelines::Stage
    include SomeStage

    def process(message, callback)
      @flip = !@flip || false
      message.rejected! if @flip
    end
  end

  class ShouldNotBeReachedStage < EmPipelines::Stage
    include SomeStage

    def process(message, callback)
      raise "should not be reached but got #{message}!"
    end
  end

  class ConsumeStage < EmPipelines::Stage
    include SomeStage

    def process(message, callback)
      message.consumed!
    end
  end

  class RejectStage < EmPipelines::Stage
    include SomeStage

    def process(message, callback)
      message.rejected!
    end
  end

  class BrokenMessageStage < EmPipelines::Stage
    include SomeStage

    def process(message, callback)
      message.broken!
    end
  end

  class ValidatesPresenceStage < EmPipelines::Stage
    include SomeStage
    extend EmPipelines::MessageValidity

    validates_presence_of_keys :a, :b, :c, :d

    def process(message, callback)
      validate!(message)
      callback.call(message)
    end
  end

  class ValidatesNumericalityStage < EmPipelines::Stage
    include SomeStage
    extend EmPipelines::MessageValidity

    validates_numericality_of_keys :c

    def process(message, callback)
      validate!(message)
      callback.call(message)
    end
  end

  class ValidatesTemporalityStage < EmPipelines::Stage
    include SomeStage
    extend EmPipelines::MessageValidity

    validates_temporality_of_keys :b

    def process(message, callback)
      validate!(message)
      callback.call(message)
    end
  end
end

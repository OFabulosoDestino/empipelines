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
    def with_em_run(&test_body)
      EM.run do
        EM.add_timer(10) do
          EM.stop
          raise "################### Test timed-out! ################### "
        end

        test_body.call
      end
    end
  end

  module SomeStage
    @@last_id = 0
    def initialize
      @id = "module ##{(@@last_id)}"
      @@last_id += 1
    end
    
    def call(message, &callback)
      processed << [@id, message.co_id]
      process(message, callback)
    end          
  end
  
  class PassthroughStage
    include SomeStage
    
    def process(message, callback)
      callback.call(message.merge!({}))
    end
  end

  class RetryOscillator
    include SomeStage

    def process(message, callback)
      @flip = !@flip || false
      message.rejected! if @flip
    end
  end

  class ShouldNotBeReachedStage
    include SomeStage
    
    def process(message, callback)
      raise "should not be reached but got #{message}!"
    end
  end

  class ConsumeStage
    include SomeStage
    
    def process(message, callback)
      message.consumed!
    end
  end
  
  class RejectStage
    include SomeStage
    
    def process(message, callback)
      message.rejected!
    end
  end
  
  class BrokenMessageStage
    include SomeStage
    
    def process(message, callback)
      message.broken!
    end
  end
end

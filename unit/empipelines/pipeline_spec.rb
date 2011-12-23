require 'empipelines/message'
require 'empipelines/pipeline'

def msg(some_map)
  EmPipelines:: MessageMock.new(some_map)
end

module EmPipelines
  class MessageMock < EmPipelines::Message
    def consumed!
      raise 'unexpected call'
    end
    
    def rejected!
      raise 'unexpected call'
    end

    def broken!
      raise 'unexpected call'
    end
  end

  class AddOne
    def call(input, &next_stage)
      next_stage.call(input.merge!({:data => (input[:data] + 1)}))
    end
  end

  class Passthrough
    def call(input, &next_stage)
      next_stage.call(input)
    end
  end

  class SquareIt
    def call(input, &next_stage)
      next_stage.call(input.merge!({:data => (input[:data] * input[:data])}))
    end
  end

  class BrokenStage
    def call(ignore, &ignored_too)
      raise 'Boo!'
    end
  end

  class DeadEnd
    def call(input, &also_ignore)
      #noop
    end
  end

  class NeedsAnApple
    def call(input, &next_stage)
      next_stage.call(input.merge!({:apple => apple}))
    end
  end

  class NeedsAnOrange
    def call(input, &next_stage)
      next_stage.call(input.merge!({:orange => orange}))
    end
  end
  
  class GlobalHolder
    @@value = nil
    def GlobalHolder.held
      @@value
    end

    def initialize
      @@value = nil
    end
    
    def call(input, &next_step)
      @@value = input
      next_step.call(input)
    end
  end

  class StubSpawner
    
    class StubProcess
      def initialize(block)
        @block = block
      end
      
      def notify(input)
        @block.call(input)
      end
    end
    
    def spawn(&block)
      StubProcess.new(block)
    end
  end

  describe Pipeline do
    let(:logger) {stub(:info => true, :debug => true)}

    it 'chains the actions using processes' do
      event_chain = [AddOne, SquareIt, GlobalHolder]
      a_msg = msg({:data =>1})
      a_msg.should_receive(:consumed!)

      pipelines = Pipeline.new(StubSpawner.new, {}, stub('monitoring'), logger)
      pipeline = pipelines.for(event_chain)
      pipeline.notify(a_msg)

      GlobalHolder.held[:data].should ==(4)
    end

    it 'does not send to the next if last returned nil' do
      event_chain = [AddOne, SquareIt, DeadEnd, GlobalHolder]
      pipelines = Pipeline.new(StubSpawner.new, {}, stub('monitoring'), logger)
      pipeline = pipelines.for(event_chain)
      pipeline.notify(msg({:data => 1}))
      GlobalHolder.held.should be_nil
    end

    it 'makes all objects in the context object available to stages' do
      event_chain = [NeedsAnApple, NeedsAnOrange, GlobalHolder]
      pipelines = Pipeline.new(StubSpawner.new, {:apple => :some_apple, :orange => :some_orange}, stub('monitoring'), logger)
      a_msg = msg({})
      a_msg.should_receive(:consumed!)

      pipeline = pipelines.for(event_chain)
      pipeline.notify(a_msg)

      GlobalHolder.held[:apple].should ==(:some_apple)
      GlobalHolder.held[:orange].should ==(:some_orange)
    end

    it 'sends exception to the proper handler' do
      monitoring = mock()
      monitoring.should_receive(:inform_exception!)
      pipeline = Pipeline.new(StubSpawner.new, {}, monitoring, logger)
      pipeline.for([BrokenStage]).notify(msg({}))
    end

    it 'flags the message as consumed if goest through all stages' do
      event_chain = [Passthrough, Passthrough]
      pipelines = Pipeline.new(StubSpawner.new, {}, stub('monitoring'), logger)
      pipeline = pipelines.for(event_chain)
      a_msg = msg({:data => :whatevah})
      a_msg.should_receive(:consumed!)

      pipeline.notify(a_msg)
    end
  end
end

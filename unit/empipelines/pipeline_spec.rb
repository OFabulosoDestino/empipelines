require "empipelines/pipeline"

module EmPipelines
  class AddOne
    def call(input, &next_stage)
      next_stage.call({:data => (input[:data] + 1)})
    end
  end

  class SquareIt
    def call(input, &next_stage)
      next_stage.call({:data => (input[:data] * input[:data])})
    end
  end

  class BrokenStage
    def call(ignore, &ignored_too)
      raise "Boo!"
    end
  end

  class DeadEnd
    def call(input, &also_ignore)
      #noop
    end
  end

  class NeedsAnApple
    def call(input, &next_stage)
      next_stage.call(input.merge({:apple => apple}))
    end
  end

  class NeedsAnOrange
    def call(input, &next_stage)
      next_stage.call(input.merge({:orange => orange}))
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
      next_step.call(self.class)
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
    it "chains the actions using processes" do
      event_chain = [AddOne, SquareIt, GlobalHolder]
      pipelines = Pipeline.new(StubSpawner.new, {}, stub('monitoring'), logger)
      pipeline = pipelines.for(event_chain)
      pipeline.notify({:data =>1})
      GlobalHolder.held.should eql({:data => 4})
    end

    it "does not send to the next if last returned nil" do
      event_chain = [AddOne, SquareIt, DeadEnd, GlobalHolder]
      pipelines = Pipeline.new(StubSpawner.new, {}, stub('monitoring'), logger)
      pipeline = pipelines.for(event_chain)
      pipeline.notify({:data => 1})
      GlobalHolder.held.should be_nil
    end

    it "makes all objects in the context object available to stages" do
      event_chain = [NeedsAnApple, NeedsAnOrange, GlobalHolder]
      pipelines = Pipeline.new(StubSpawner.new, {:apple => :some_apple, :orange => :some_orange}, stub('monitoring'), logger)
      pipeline = pipelines.for(event_chain)
      pipeline.notify({})
      GlobalHolder.held.should eql({:apple => :some_apple, :orange => :some_orange})
    end

    it "sends exception to the proper handler" do
      monitoring = mock()
      monitoring.should_receive(:inform_exception!)
      pipeline = Pipeline.new(StubSpawner.new, {}, monitoring, logger)
      pipeline.for([BrokenStage]).notify({})
    end
  end
end

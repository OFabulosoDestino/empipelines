require 'empipelines'

def msg(some_map)
  EmPipelines:: MessageMock.new(some_map)
end

module EmPipelines
  class MessageMock < EmPipelines::Message
    def consumed!
      raise "consumed! should not have been called"
    end

    def rejected!
      raise "rejected! should not have been called"
    end

    def broken!
      raise "broken! should not have been called"
    end
  end

  class Passthrough < EmPipelines::Stage
  end

  class EnsureNotNil < EmPipelines::Stage
    extend EmPipelines::MessageValidity

    validates_presence_of_keys :a

    def call(input, &next_stage)
      validate!(input) && next_stage.call(input)
    end
  end

  class AddOne < EmPipelines::Stage
    def call(input, &next_stage)
      next_stage.call(input.merge!({:data => (input[:data] + 1)}))
    end
  end

  class SquareIt < EmPipelines::Stage
    def call(input, &next_stage)
      next_stage.call(input.merge!({:data => (input[:data] * input[:data])}))
    end
  end

  class BrokenStage < EmPipelines::Stage
    def call(ignore, &ignored_too)
      raise "Boo!"
    end
  end

  class DeadEnd < EmPipelines::Stage
    def call(input, &also_ignore)
      #noop
    end
  end

  class NeedsAnApple < EmPipelines::Stage
    def call(input, &next_stage)
      next_stage.call(input.merge!({:apple => apple}))
    end
  end

  class NeedsAnOrange < EmPipelines::Stage
    def call(input, &next_stage)
      next_stage.call(input.merge!({:orange => orange}))
    end
  end

  class GlobalHolder < EmPipelines::Stage
  end

  class MockEM
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
    let(:logging) { mock_logging(false) }
    let(:em) { MockEM.new }
    let(:services) { { :foo => 4, :bar => Object.new, :baz => "a thing!", :logging => logging } }
    let(:stages) { [ AddOne, SquareIt, GlobalHolder ] }
    let(:pipeline) { Pipeline.new(em, services) }

    context "#initialize" do
      it "sets instance variables, defines attr_accessors" do
        pipeline.em.should ==(em)
        pipeline.services.should ==(services)
        pipeline.services[:logging].should ==(services[:logging])
      end
    end

    context "#for" do
      it "instantiates each Stage subclass, injects @services" do
        stages.each do |e|
          e.should_receive(:new).with(hash_including(services))
        end

        pipeline.for(stages)
      end

      it "for each service, each stage has an instance variable defined on it which points to the service instance" do
        pipeline.for(stages)

        pipeline.
          stages.
            each do |stage|
              services.each do |k,v|
                stage.send(k).should ==(v)
              end
            end
      end

      context "with a Validation Stage" do
        let(:stages) { [ AddOne, SquareIt, GlobalHolder ] << EnsureNotNil }

        it "should instantiate the Validation Stage properly" do
          pipeline = Pipeline.new(em, services)
          pipeline.for(stages)

          stage = pipeline.stages.find { |s| EnsureNotNil === s }

          stage.should_not be_nil
          stage.should respond_to(:validate!)
          stage.validations.should_not be_empty
        end
      end
    end

    context "#notify" do
      it "does not call the next if last returned nil" do
        GlobalHolder.should_not_receive(:call)

        stages = [AddOne, SquareIt, DeadEnd, GlobalHolder]
        pipelines = Pipeline.new(em, services)
        pipeline = pipelines.for(stages)
        pipeline.notify(msg({:data => 1}))
      end

      it "marks message as broken if uncaught exception" do
        a_msg = msg({})
        logging.should_receive(:error)

        a_msg.should_receive(:broken!)

        pipeline = Pipeline.new(em, services)
        pipeline.for([BrokenStage]).notify(a_msg)
      end

      it "flags the message as consumed if it goes through all stages" do
        stages = [Passthrough, AddOne, Passthrough, SquareIt, Passthrough]
        pipelines = Pipeline.new(em, services)
        pipeline = pipelines.for(stages)
        a_msg = msg({:data => 1})
        a_msg.should_receive(:consumed!)

        pipeline.notify(a_msg)
      end
    end
  end
end

require 'empipelines'

def msg(some_map)
  EmPipelines:: MessageMock.new(some_map)
end

module EmPipelines
  class MessageMock < Message
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

  class Passthrough < Stage
  end

  class EnsureNotNil < Stage
    extend EmPipelines::MessageValidity

    validates_presence_of_keys :a

    def call(message, &callback)
      validate!(message) && callback.call(message)
    end
  end

  class AddOne < Stage
    def call(message, &callback)
      callback.call(message.merge!({:data => (message[:data] + 1)}))
    end
  end

  class SquareIt < Stage
    def call(message, &callback)
      callback.call(message.merge!({:data => (message[:data] * message[:data])}))
    end
  end

  class BrokenStage < Stage
    def call(message, &callback)
      message.broken!
    end
  end

  class ExceptionStage < Stage
    def call(message, &callback)
      raise "Boo!"
    end
  end

  class NeedsAnApple < Stage
    def call(message, &callback)
      callback.call(message.merge!({:apple => apple}))
    end
  end

  class NeedsAnOrange < Stage
    def call(message, &callback)
      callback.call(message.merge!({:orange => orange}))
    end
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
    let(:logging) { mock_logging }
    let(:em) { MockEM.new }
    let(:services) { { :foo => 4, :bar => Object.new, :baz => "a thing!", :logging => logging } }
    let(:stages) { [ AddOne, SquareIt, Passthrough ] }
    let(:pipeline) { Pipeline.new(em, services) }

    context "#initialize" do
      it "sets instance variables, defines attr_accessors" do
        pipeline.em.should ==(em)
        pipeline.services.should ==(services)
        pipeline.services[:logging].should ==(logging)
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

      context "inter-stage behavior" do
        let(:pipeline) { Pipeline.new(em, services, stages) }
        let(:message) { MessageMock.new({:a => "b"}) }
        let(:prev_stage) { stages[0] }
        let(:next_stage) { stages[1] }

        before { message.instance_variable_set("@state", state) }

        shared_examples_for "a message in halting state" do
          it ": doesnt propagate the message and informs monitoring of state and pipeline stop" do
            stages.each{ |stage| stage.should_not_receive(:call) }
            pipeline.services[:logging].should_receive(:info).with("Pipeline: stopping propagation.")
            pipeline.services[:logging].should_receive(severity)
            pipeline.services[:logging].should respond_to(:info)

            pipeline.send(:monitor_state, message, next_stage)
            pipeline.send(:propagate_or_halt, message, prev_stage, next_stage)
          end
        end

        shared_examples_for "a message in propagating state" do
          it ": propagates the message and informs monitoring correctly" do
            next_stage.should_receive(:call)
            (stages - [next_stage]).map { |stage| stage.should_not_receive(:call) }
            pipeline.services[:logging].should_receive(severity).with(/#{state.to_s}/)
            pipeline.services[:logging].should respond_to(:info)

            pipeline.send(:monitor_state, message, next_stage)
            pipeline.send(:propagate_or_halt, message, prev_stage, next_stage)
          end
        end

        context "with message state" do
          context "broken" do
            let(:state) { :broken }
            let(:severity) { :error }

            it_should_behave_like "a message in halting state"
          end

          context "rejected" do
            let(:state) { :rejected }
            let(:severity) { :error }

            it_should_behave_like "a message in halting state"
          end

          context "consumed" do
            let(:state) { :consumed }
            let(:severity) { :info }

            it_should_behave_like "a message in halting state"
          end

          context "created" do
            let(:state) { :created }
            let(:severity) { :info }

            it_should_behave_like "a message in propagating state"
          end

          context "other" do
            let(:state) { :haaaaaiiiiiii }
            let(:severity) { :warn }

            it_should_behave_like "a message in propagating state"
          end
        end
      end

      context "with a Validation Stage" do
        let(:stages) { [ AddOne, SquareIt, Passthrough, EnsureNotNil ] }
        let(:pipeline) { Pipeline.new(em, services) }

        it "should instantiate the Validation Stage properly" do
          pipeline.for(stages)
          stage = pipeline.stages.find { |s| EnsureNotNil === s }

          stage.should_not be_nil
          stage.should respond_to(:validate!)
          stage.validations.should_not be_empty
        end
      end
    end

    context "#notify" do
      let(:stages) { [ AddOne, Passthrough, BrokenStage, SquareIt ] }
      let(:pipeline) { Pipeline.new(em, services, stages) }
      let(:message) { Message.new({:data => 1}) }

      it "does not call the next if last returned nil" do
        pipeline.stages.first.should_receive(:call)
        pipeline.stages.last.should_not_receive(:call)

        pipeline.for.notify(message)
      end

      it "raises uncaught exceptions thrown within stages" do
        expect do
          pipeline = Pipeline.new(em, services)
          pipeline.for([ ExceptionStage ]).notify(message)

        end.to raise_error("Boo!")
      end

      it "flags the message as consumed if it goes through all stages" do
        stages = [ Passthrough, AddOne, Passthrough, SquareIt, Passthrough ]
        pipelines = Pipeline.new(em, services)
        message.should_receive(:consumed!)

        pipelines.for(stages).notify(message)
      end
    end
  end
end

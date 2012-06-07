require "eventmachine"
require "empipelines"
require "amqp"
require "json"
require File.join(File.dirname(__FILE__), "test_stages")

module TestStages
  describe "Consumption of events from a in-memory batch" do
    let(:logging) { mock_logging }
    let(:services) { { logging: logging } }
    let(:processed) { [] }
    let(:timeout) { 2 }

    include EmRunner

    it "consumes all events from a queue" do
      with_em_timeout(timeout) do
        exchange, queue = TestStages.setup_queues

        messages = (1..1000).map { |i| {:data => i}.to_json }
        messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

        pipeline = EmPipelines::Pipeline.new(EM, services.merge({ :processed => processed }))
        source = EmPipelines::AmqpEventSource.new(EM, queue, "msg", services)

        stages = [TestStages::PassthroughStage, TestStages::PassthroughStage, TestStages::PassthroughStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), services)

        pipeline.stages.size.should ==(stages.size)

        EM.add_periodic_timer(0.1) do
          if processed.size == messages.size * stages.size then
            EM.stop
          end
        end

        event_pipeline.start!
      end
    end

    it "discards broken messages" do
      with_em_timeout(timeout) do
        exchange, queue = TestStages.setup_queues

        messages = (1..1000).map { |i| {:data => i}.to_json }
        messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

        pipeline = EmPipelines::Pipeline.new(EM, services.merge({ :processed => processed }))
        source = EmPipelines::AmqpEventSource.new(EM, queue, "msg", services)

        stages = [TestStages::BrokenMessageStage, TestStages::ShouldNotBeReachedStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), services)

        pipeline.stages.size.should ==(stages.size)

        EM.add_periodic_timer(0.1) do
          if processed.size == messages.size then
            EM.stop
          end
        end

        event_pipeline.start!
      end
    end

    it "retries messages if told to do so" do
      with_em_timeout(timeout) do
        exchange, queue = TestStages.setup_queues

        messages = [ {:data => "b"}.to_json ]
        messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

        pipeline = EmPipelines::Pipeline.new(EM, services.merge({ :processed => processed }))
        source = EmPipelines::AmqpEventSource.new(EM, queue, "msg", services)

        stages = [TestStages::RetryOscillator]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), services)

        pipeline.stages.size.should ==(stages.size)

        EM.add_periodic_timer(0.1) do
          if processed.size == 2 then
            EM.stop
          end
        end

        event_pipeline.start!
      end
    end
  end
end

require 'eventmachine'
require 'empipelines'
require 'amqp'
require 'json'
require File.join(File.dirname(__FILE__), 'test_stages')

ExchangeName = 'empipelines.build'
QueueName = 'empipelines.build.queue'

def setup_queues
  connection = AMQP.connect()
  channel = AMQP::Channel.new(connection)
  channel.prefetch(1)

  exchange = channel.direct(ExchangeName, :durable => true)
  queue = channel.queue(QueueName, :durable => true)
  queue.bind(exchange)
  queue.purge
  [exchange, queue]
end

module TestStages

  describe 'Consumption of events from a in-memory batch' do
    let(:monitoring) { Monitoring.new }
    let (:processed) { [] }

    include EmRunner

    it 'consumes all events from a queue' do
      with_em_timeout(10) do
        exchange, queue = setup_queues

        messages = (1..1000).map { |i| {:data => i}.to_json }
        messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

        pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
        source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)

        stages = [PassthroughStage, PassthroughStage, PassthroughStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

        EM.add_periodic_timer(0.1) do
          if processed.size == messages.size * stages.size then
            EM.stop
          end
        end

        event_pipeline.start!
      end
    end

    it 'discards broken messages' do
            with_em_timeout(10) do
        exchange, queue = setup_queues

        messages = (1..1000).map { |i| {:data => i}.to_json }
        messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

        pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
        source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)

        stages = [BrokenMessageStage, ShouldNotBeReachedStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

        EM.add_periodic_timer(0.1) do
          if processed.size == messages.size then
            EM.stop
          end
        end

        event_pipeline.start!
      end
    end

    it 'retries messages if told to do so' do
      with_em_timeout(10) do
        exchange, queue = setup_queues

        messages = [ {:data => "b"}.to_json ]
        messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

        pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
        source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)

        stages = [RetryOscillator]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

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

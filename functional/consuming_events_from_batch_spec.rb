require 'eventmachine'
require 'empipelines'
require File.join(File.dirname(__FILE__), 'test_stages')

module TestStages
  describe 'Consumption of events from a in-memory batch' do
    let(:monitoring) { TestStages::MockMonitoring.new }
    let(:processed) { [] }
    include EmRunner

    it 'consumes all events from the a queue' do
      with_em_timeout(2) do
        pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)

        batch = (1...1000).to_a
        batch_name = "my batch!"
        source = EmPipelines::BatchEventSource.new(EM, batch_name, batch)

        stages = [PassthroughStage, PassthroughStage, PassthroughStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

        source.on_finished do |s|
          EM.stop
          s.should ==(source)
        end

        event_pipeline.start!
      end
    end
  end
end

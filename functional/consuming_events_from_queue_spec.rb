require 'eventmachine'
require 'empipelines'
require File.join(File.dirname(__FILE__), 'test_stages')

module TestStages
  describe 'Consumption of events from a queue' do
    let(:monitoring) { stub() }
    let(:logger) { stub(:info => nil, :debug => nil) }
    let (:processed) { {} }
    include EmRunner

    it 'consumes all events from the a queue' do
      with_em_run do
        pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring, logger)

        batch = (1...1000).to_a
        batch_name = "my batch!"
        source = EmPipelines::BatchEventSource.new(EM, batch_name, batch)

        stages = [PassthroughStage, PassthroughStage, PassthroughStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

        source.on_finished do |messages|
          EM.stop
          (messages.all?{ |m| m.state == :consumed }).should be_true
          (messages.all?{ |m| m [:origin] == batch_name }).should be_true
          (messages.map{ |m| m[:payload] }).should ==(batch)
        end

        event_pipeline.start!
      end
    end
  end
end

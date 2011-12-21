require 'eventmachine'
require 'empipelines'
require File.join(File.dirname(__FILE__), 'test_stages')

module TestStages
  describe 'Consumption of events from a file' do
    let(:monitoring) { stub() }
    let(:logger) { stub(:info => nil, :debug => nil) }
    let (:processed) { {} }
    include EmRunner

    it 'consumes all events from the file' do
      with_em_run do      
        pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring, logger)

        file_name = File.join(File.dirname(__FILE__), 'events.dat')
        source = EmPipelines::IOEventSource.new(EM, file_name)

        stages = [PassthroughStage, PassthroughStage, PassthroughStage, ConsumeStage]
        event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

        source.on_finished do |messages|
          EM.stop  
          messages.should have(10).items
          messages[0][:payload].should ==("event #0")
          messages[1][:payload].should ==("event #1")
          messages[2][:payload].should ==("event #2")
          messages[3][:payload].should ==("event #3")
          messages[4][:payload].should ==("event #4")
          messages[5][:payload].should ==("event #5")
          messages[6][:payload].should ==("event #6")
          messages[7][:payload].should ==("event #7")
          messages[8][:payload].should ==("event #8")
          messages[9][:payload].should ==("event #9")
          messages.each { |m| m.state.should ==(:consumed) }        
        end
        
        event_pipeline.start!
      end
    end
  end
end

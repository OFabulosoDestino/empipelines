require 'eventmachine'
require 'empipelines'
require File.join(File.dirname(__FILE__), 'test_stages')

module TestStages
  describe 'Consumption of events from multiple sources' do
    let(:monitoring) { stub(:inform => nil, :debug => nil) }
    let (:processed) { {} }
    include EmRunner

    it 'consumes all events from all sources' do
      pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)

      file_name = File.join(File.dirname(__FILE__), 'events.dat')
      num_events_on_file = IO.readlines(file_name).size
      io_source = EmPipelines::IOEventSource.new(EM, file_name)

      batch = (1...1000).to_a
      batch_name = "my batch!"
      batch_source = EmPipelines::BatchEventSource.new(EM, batch_name, batch)

      composed_event_source = EmPipelines::AggregatedEventSource.new(EM, batch_source, io_source)

      composed_event_source.on_finished do |s|
        EM.stop
        s.should ==(composed_event_source)
      end
    end
  end
end

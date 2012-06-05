# encoding: utf-8
require "eventmachine"
require "empipelines"
require "json"
require File.join(File.dirname(__FILE__), "test_stages")

module TestStages
  describe "from AmqpEventSource" do
    let(:monitoring) { MockMonitoring.new }
    let(:processed) { [] }
    let(:messages) { }
    let(:timeout) { 0.01 }

    include EmRunner

    context "processing valid messages" do
      let(:messages) do
        [
          {
            :a => "the smallest weird number",
            :b => "1:23:09 CST",
            :c => 3,
            :d => "about €20",
            :e => { :catchphrases => [ "chicken tikka masala" ] },
          },
          {
            :a => "the smallest weird number",
            :b => "1:23:10 CST",
            :c => "4",
            :d => "☃",
            :e => { :catchphrases => [ "USA!! USA!!! USA!!!!" ] },
          },
        ].map(&:to_json)
      end

      it "pipeline executes each stage without errors" do
        monitoring.should_receive(:debug).any_number_of_times
        monitoring.should_not_receive(:error)
        monitoring.should_not_receive(:inform_exception!)

        expect do
          EM.run do
            exchange, queue = TestStages.setup_queues
            messages.each { |m| exchange.publish(m, :rounting_key => "empipelines.build.queue") }
            pipeline = EmPipelines::Pipeline.new(EM, { :processed => processed }, monitoring)
            source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)
            stages = [ TestStages::ValidatesPresenceStage ]
            event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

            EM.add_timer(timeout) do
              EM.stop
              processed.size.should ==(stages.size * messages.size)
            end

            event_pipeline.start!
          end
        end.to_not raise_error
      end
    end

    context "processing invalid messages" do
      let(:messages) do
        [
          {
            :a => "the smallest weird number",
            :b => "all! the! time!",
            :c => 3,
            :d => nil,
          },
        ].map(&:to_json)
      end

      it "pipeline executes each stage, monitoring receives every validation error for every executed stage" do
        monitoring.should_receive(:inform).any_number_of_times
        monitoring.should_receive(:debug).any_number_of_times
        monitoring.should_receive(:error).with(/required keys were not present(.*?):d/).once
        monitoring.should_receive(:error).with(/values required to be be parsed as Time couldn't be(.*?):b/).once
        monitoring.should_not_receive(:inform_exception!)

        EM.run do
          exchange, queue = TestStages.setup_queues
          pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
          source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)
          stages = [ TestStages::ValidatesNumericalityStage, TestStages::ValidatesNumericalityStage, TestStages::ValidatesTemporalityStage, TestStages::ValidatesPresenceStage ]
          event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

          messages.each { |m| exchange.publish(m, :rounting_key => "empipelines.build.queue") }

          # TODO: run without relying on a fixed amount of time
          EM.add_timer(timeout) do
            EM.stop
            processed.size.should ==(stages.size * messages.size)
          end

          event_pipeline.start!
        end
      end
    end
  end
end

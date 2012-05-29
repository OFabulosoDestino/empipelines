# encoding: utf-8
require "eventmachine"
require "empipelines"
require "json"
require File.join(File.dirname(__FILE__), "test_stages")

ExchangeName = "empipelines.build"
QueueName = "empipelines.build.queue"

module TestStages
  describe "Consumption of events from multiple sources" do
    let(:monitoring) { stub(:inform => nil, :debug => nil) }
    let(:processed) { [] }
    let(:messages) { }

    include EmRunner

    context "processing valid messages" do
      let(:messages) do
        [
          {
            :foo => 1,
            :bar => 2,
            :top_level_key => {
              :a => "the smallest weird number",
              :b => "1:23:09 CST",
              :c => "about €20",
              :d => 3,
              :e => "chicken tikka masala",
            },
          },
          {
            :foo => 3,
            :bar => 4,
            :top_level_key => {
              :a => "the smallest weird number",
              :b => "1:23:10 CST",
              :c => "☃",
              :d => "4",
              :e => "USA! USA!! USA!!!",
            },
          },
        ].map(&:to_json)
      end

      it "pipeline executes #process for each stage without informing errors" do
        monitoring.should_not_receive(:inform_error!)
        monitoring.should_not_receive(:inform_exception!)

        EM.run do
          exchange, queue = setup_queues

          messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

          pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
          source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)

          stages = [ValidatesPresenceStage, ValidatesNumericalityStage]
          event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

          EM.add_timer(1) do
            EM.stop
            processed.size.should ==(stages.size * messages.size)
          end

          event_pipeline.start!
        end
      end
    end
  end
end

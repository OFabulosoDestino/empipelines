# encoding: utf-8
require "eventmachine"
require "empipelines"
require "json"
require File.join(File.dirname(__FILE__), "test_stages")

ExchangeName = "empipelines.build"
QueueName = "empipelines.build.queue"

module TestStages
  describe "Consumption of events from multiple sources" do
    let(:monitoring) { stub(:inform => nil, :debug => nil, :error => nil) }
    let(:processed) { [] }
    let(:messages) { }

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

      it "pipeline executes #process for each stage without errors" do
        monitoring.should_not_receive(:error)

        expect do
          EM.run do
            exchange, queue = setup_queues

            messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

            pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
            source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)

            stages = [ ValidatesPresenceStage]
            event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

            EM.add_timer(1) do
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
        monitoring.should_receive(:error).with(/required keys were not present(.*?):d/).once
        monitoring.should_receive(:error).with(/values required to be be parsed as Time couldn't be(.*?):b/).once

        error_count = 2
        EM.run do
          exchange, queue = setup_queues

          messages.each { |m| exchange.publish(m, :rounting_key => QueueName) }

          pipeline = EmPipelines::Pipeline.new(EM, {:processed => processed}, monitoring)
          source = EmPipelines::AmqpEventSource.new(EM, queue, 'msg', monitoring)

          stages = [ValidatesPresenceStage, ValidatesNumericalityStage, ValidatesTemporalityStage]
          event_pipeline = EmPipelines::EventPipeline.new(source, pipeline.for(stages), monitoring)

          EM.add_timer(1) do
            EM.stop
          end

          event_pipeline.start!
        end
      end
    end
  end
end

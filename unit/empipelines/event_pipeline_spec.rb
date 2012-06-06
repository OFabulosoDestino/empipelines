require 'empipelines'

module EmPipelines
  class StubSource
    def initialize(event_data)
      @event_data = event_data
    end

    def start!
      @handler.call(@event_data)
    end

    def on_event(&event_handler)
      @handler = event_handler
    end
  end

  describe EventPipeline do
    it "binds a source to a pipeline" do
      monitoring = stub(:increment => nil)
      event = stub('event')
      pipeline = stub('processing pipeline')
      source = StubSource.new(event)

      pipeline.should_receive(:notify).with(event)

      event_pipeline = EventPipeline.new(source, pipeline, monitoring)
      event_pipeline.start!
    end
  end
end

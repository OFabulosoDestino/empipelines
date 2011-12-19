module Pipelines
  class EventPipeline
    def initialize(source, pipeline, monitoring)
      @source, @pipeline, @monitoring = source, pipeline, monitoring

      @source.on_event do |event_data|
        @pipeline.notify(event_data)
      end
    end

    def start!
      @source.start!
    end
  end
end

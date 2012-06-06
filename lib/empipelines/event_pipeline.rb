module EmPipelines
  class EventPipeline
    # TODO: what is the difference/relationship
    # between an EventPipeline and a Pipeline?
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

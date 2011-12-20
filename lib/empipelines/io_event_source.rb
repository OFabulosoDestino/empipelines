require 'empipelines/event_handlers'

module EmPipelines
  class IOEventSource
    include EventHandlers

    def initialize(em, file_path)
      raise "File #{file_path} does not exist!" unless File.exists?(file_path)
      @em, @file_path = em, file_path
    end
    
    def start!
      #TODO: this sucks hard, move to evented I/O
      events = IO.readlines(@file_path)

      wrapped_handler = BatchEventSource.new(@em, events)
      wrapped_handler.on_event(event_handler)
      wrapped_handler.on_finished(finished_handler)
      wrapped_handler.start!
    end
  end
end

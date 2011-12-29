require 'empipelines/event_source'

module EmPipelines
  class IOEventSource < EventSource

    def initialize(em, file_path)
      raise "File #{file_path} does not exist!" unless File.exists?(file_path)
      @em, @file_path = em, file_path
    end
    
    def start!
      #TODO: this sucks hard, move to evented I/O
      events = IO.readlines(@file_path).map { |e| e.strip }

      wrapped_handler = BatchEventSource.new(@em, @file_path, events)
      wrapped_handler.on_event(event_handler)
      wrapped_handler.on_finished { |*ignored| finished_handler.call(self) }
      wrapped_handler.start!
    end
  end
end

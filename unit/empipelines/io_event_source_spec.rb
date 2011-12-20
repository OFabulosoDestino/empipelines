require 'empipelines/io_event_source'

module EmPipelines
  describe IOEventSource do    
    let(:events_file) { File.join(File.dirname(__FILE__), 'io_event_source.dat')}
    let(:empty_file) { File.join(File.dirname(__FILE__), 'empty_io_event_source.dat')}
    let(:inexistent_file) { File.join(File.dirname(__FILE__), 'not_really_son.dat')}
    let (:em) do
      em = mock('eventmachine')
      em.stub(:next_tick).and_yield
      em
    end

    it 'verifies file existance'  do
      lambda{ IOEventSource.new(em, inexistent_file) }.should raise_error
    end
    
    it 'sends each line in the file as payload to listeners' do
      source = IOEventSource.new(em, events_file)

      received = []
      source.on_event do |e|
        received << e
      end

      source.start!

      received.map{ |i| i[:payload].to_i }.should ==([1,2,3])
    end
    
    it 'calls the finished callback when all messages were processed' do
      source = IOEventSource.new(em, events_file)

      has_finished = []

      source.on_finished do |messages|
        has_finished << messages
      end

      source.on_event do |e|
        e.consumed!
      end

      source.start!

      has_finished.first.map{ |i| i[:payload].strip.to_i }.should ==([1,2,3])
    end
    
    it 'finishes immediately if there are no events to process' do
      source = IOEventSource.new(em, empty_file)

      has_finished = []
      source.on_finished do |messages|
        has_finished << true
      end

      source.on_event do |e|
        raise 'should not be called!'
      end

      source.start!

      has_finished.first.should be_true
    end
    
    it 'only calls the finished handler if all events were processed' do
      source = IOEventSource.new(em, events_file)

      source.on_finished do |messages|
        raise "should not be called"
      end

      count = 0
      source.on_event do |e|
        e.consumed! if (count=+1) > 1
      end

      source.start!
    end

    it 'can read really long files' do
      pending('current implementation is terribly naive')
    end
  end
end

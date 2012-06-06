require 'empipelines'

module EmPipelines
  ShouldNotBeCalled = lambda { |*x| raise 'should not be called' }
  describe BatchEventSource do

    let (:em) do
      em = mock('eventmachine')
      em.stub(:next_tick).and_yield
      em
    end

    let (:list_name) { 'list of stuff'  }

    it 'sends each element on the list as a payload to the listener' do
      events = [1,2,3,4,5,6,7,8,9,10]
      source = BatchEventSource.new(em, list_name, events)

      received = []
      source.on_event do |e|
        received << e
      end

      source.start!

      received.map{ |i| i[:payload] }.should ==(events)
      received.each{ |i| i[:origin].should == list_name }
    end

    it 'calls the batch finished callback when all items were processed' do
      events = [1,2,3,4,5,6,7,8,9,10]
      source = BatchEventSource.new(em, list_name, events)

      has_finished = [false]

      source.on_finished do |s|
        s.should ==(source)
        has_finished[0] = true
      end

      source.on_event do |e|
        e.consumed!
      end

      source.start!

      has_finished.first.should be_true
    end

    it 'finishes immediately if there are no events to process' do
      source = BatchEventSource.new(em, list_name, [])

      has_finished = []
      source.on_finished do |s|
        s.should ==(source)
        has_finished << true
      end

      source.on_event(ShouldNotBeCalled)

      source.start!

      has_finished.first.should be_true
    end

    it 'only calls the finished handler if all events were processed' do
      events = [1,2,3,4,5,6,7,8,9,10]
      source = BatchEventSource.new(em, list_name, events)

      count = 0
      source.on_event do |e|
        e.consumed! if (count=+1) > 1
      end

      source.start!
    end
  end
end

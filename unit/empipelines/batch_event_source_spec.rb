require 'empipelines/batch_event_source'

module EmPipelines
  describe BatchEventSource do

    let (:em) do
      em = mock('eventmachine')
      em.stub(:next_tick).and_yield
      em
    end

    it "sends each element on the list as a payload to the listener" do
      events = [1,2,3,4,5,6,7,8,9,10]
      source = BatchEventSource.new(em, events)

      received = []
      source.on_event do |e|
        received << e
      end

      source.start!

      received.map{ |i| i[:payload] }.should ==(events)
    end

    it "calls the batch finished callback when all items were processed" do
      events = [1,2,3,4,5,6,7,8,9,10]
      source = BatchEventSource.new(em, events)

      has_finished = []

      source.on_finished do |messages|
        has_finished << messages
      end

      source.on_event do |e|
        e.consumed!
      end

      source.start!

      has_finished.first.map{ |i| i[:payload] }.should ==(events)
    end

    it "finishes immediately if there are no events to process" do
      source = BatchEventSource.new(em, [])

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

    it "only calls the finished handler if all events were processed" do
      events = [1,2,3,4,5,6,7,8,9,10]
      source = BatchEventSource.new(em, events)

      source.on_finished do |messages|
        raise "should not be called"
      end

      count = 0
      source.on_event do |e|
        e.consumed! if (count=+1) > 1
      end

      source.start!
    end
  end
end

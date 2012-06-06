require 'empipelines'

module EmPipelines
  describe PeriodicEventSource do
    it 'schedules itself with eventmachine' do
      em = stub('eventmachine')
      em.should_receive(:add_periodic_timer).with(5)
      PeriodicEventSource.new(em, 'a name', 5){ 'something cool!' }.start!
    end

    it 'sends the result of the periodic action to the handler' do
      name = 'some name'
      event = {:this => :is, :some => 'event'}
      received_messages = []

      source = PeriodicEventSource.new(stub('eventmachine'), name, 666){ event }
      source.on_event { |msg| received_messages << msg}
      source.tick!

      received_messages.should have(1).item
      received_messages[0][:payload].should eql(event)
      received_messages[0][:origin].should eql(name)
    end

    it 'doesnt o anything if no event was generated' do
      source = PeriodicEventSource.new(stub('eventmachine'), 'a name', 666){ nil }
      source.on_event { |m| raise 'should not be called' }
      source.tick!
    end
  end
end

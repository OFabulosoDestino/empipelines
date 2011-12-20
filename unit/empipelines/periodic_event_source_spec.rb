require 'empipelines/periodic_event_source'

module EmPipelines
  describe PeriodicEventSource do
    it 'schedules itself with eventmachine' do
      em = stub('eventmachine')
      em.should_receive(:add_periodic_timer).with(5)
      PeriodicEventSource.new(em, 5){ "something cool!" }.start!
    end
    
    it 'sends the result of the periodic action to the handler' do
      expected_message = { :something => "goes here" }
      received_messages = []

      source = PeriodicEventSource.new(stub('eventmachine'), 666){ expected_message }
      source.on_event { |msg| received_messages << msg}      
      source.tick!

      received_messages.should eql([expected_message])      
    end
    
    it 'doesnt o anything if no event was generated' do      
      source = PeriodicEventSource.new(stub('eventmachine'), 666){ nil }
      source.on_event { |m| raise "should not be called" }      
      source.tick!
    end
  end  
end

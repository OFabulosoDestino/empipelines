require 'empipelines/list_event_source'

module EmPipelines
  describe ListEventSource do
    it 'calls finished when list finishes' do
      items = [1, 2, 3]
      received = []

      source = ListEventSource.new('name', items)
      source.on_event { |msg| received << msg }
      source.on_finished { |s| received. << s }
      source.start!

      received.find_all { |i| i == source }.should have(1).items
      received.last.should eql(source)
    end
    
    it 'sends each element of the list to the handler' do
      name = 'my list'
      items = [1, 2, 3, 4, 5, 6]
      received_messages = []

      source = ListEventSource.new(name, items)
      source.on_event { |msg| received_messages << msg }      
      source.start!

      received_messages.map(&:payload).should eql(items)
      received_messages.each { |m| m[:origin].should ==(name) }
    end
  end  
end

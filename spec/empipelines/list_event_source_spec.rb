require 'empipelines/list_event_source'

module Pipelines
  describe ListEventSource do
    it 'sends each element of the list to the handler' do
      items = [1, 2, 3, 4, 5, 6]
      expected_messages = items.map { |i| {:payload => i} }
      received_messages = []

      source = ListEventSource.new(items)
      source.on_event { |msg| received_messages << msg}      
      source.start!

      received_messages.should eql(expected_messages)    
    end
  end  
end

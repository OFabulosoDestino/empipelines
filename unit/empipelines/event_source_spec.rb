require 'empipelines'

module EmPipelines
  class StubEventSource < EventSource
    def event_now!(message)
      event!(message)
    end

    def finish_now!
      finished!
    end
  end

  describe EventSource do
    context 'calling event handlers' do
      it 'calls the handler when an message is to be processed' do
        message = stub('message')
        received = []

        source = StubEventSource.new
        source.on_event { |a| received << a }
        source.event_now!(message)
        received.should==([message])
      end

      it 'calls the finished handler when all events were processed' do
        message = stub('message')
        received = []

        source = StubEventSource.new
        source.on_finished { |a| received << a }
        source.finish_now!
        received.should==([source])
      end

      it 'does not do anything if no handlers' do
        StubEventSource.new.event_now!({})
        StubEventSource.new.finish_now!
      end
    end

    context 'multiple event handlers' do
      let(:message1) { Message.new({:a => 1}) }
      let(:message2) { Message.new({:b => 2}) }

      def mark_as(state)
        lambda {|m| m.send "#{state}!".to_sym }
      end

      def should_be_marked_as(desired, message)
        undesired = [:broken, :consumed, :rejected] - [desired]
        undesired.each { |u| message.should_not_receive("#{u}!".to_sym) }
        message.should_receive("#{desired}!".to_sym)
        message.should_receive(:copy).at_least(:once).and_return { Message.new({}) }
      end

      it 'supports multiple handlers for a single event'do
        received = []
        finished = []

        source = StubEventSource.new
        source.on_event([lambda {|m| received << [1, m.payload]}, lambda {|m| received << [2, m.payload]}])
        source.on_event {|m| received << [3, m.payload]}

        source.on_finished {|s| finished << [10, s]}
        source.on_finished([lambda {|s| finished << [20, s]}, lambda {|s| finished << [30, s]}])

        source.event_now!(message1)
        source.event_now!(message2)
        source.finish_now!

        received.should ==([
                            [1, message1.payload],
                            [2, message1.payload],
                            [3, message1.payload],
                            [1, message2.payload],
                            [2, message2.payload],
                            [3, message2.payload]
                           ])

        finished.should ==([[10, source], [20, source], [30, source]])
      end

      it 'marks the message as consumed if all handlers consume' do
        message = mock('message')
        should_be_marked_as(:consumed, message)

        source = StubEventSource.new
        source.on_event([mark_as(:consumed), mark_as(:consumed), mark_as(:consumed)])
        source.event_now!(message)
      end

      it 'marks the message as rejects if at least one handler rejects and all others consumed' do
        message = mock('message')
        should_be_marked_as(:rejected, message)

        source = StubEventSource.new
        source.on_event([mark_as(:consumed), mark_as(:consumed), mark_as(:rejected), mark_as(:consumed)])
        source.event_now!(message)
      end

      it 'marks message as broken if at least one handler marks as broken, regardless of others' do
        message = mock('message')
        should_be_marked_as(:broken, message)

        source = StubEventSource.new
        source.on_event([mark_as(:consumed), mark_as(:consumed), mark_as(:rejected), mark_as(:consumed), mark_as(:broken)])
        source.event_now!(message)
      end
    end

    context 'flow control' do
    end
  end
end

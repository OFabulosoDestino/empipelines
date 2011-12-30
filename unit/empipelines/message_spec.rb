require 'empipelines/message'

module EmPipelines
  describe Message do
    context 'mostly behaves like a hashmap' do
      it 'stores values under symbolised keys' do
        original_hash = {:a => 1, :b => 2}

        message = Message.new(original_hash)

        message[:a].should ==(original_hash[:a])
        message[:b].should ==(original_hash[:b])
        message[:doesntexist].should ==(original_hash[:doesntexist])
      end

      it 'symbolises keys of all maps in the message' do
        message = Message.new({
                                :a => 1,
                                'b' => 2,
                                3 => 3 ,
                                'd' => {
                                  'd1' => {'e' => 5},
                                  'd2' => nil}
                              })
        message[:a].should ==(1)
        message[:b].should ==(2)
        message['3'.to_sym].should ==(3)
        message[:d][:d1][:e].should ==(5)
        message[:d][:d2].should be_nil
      end
      
      it 'allows for values to be CRUD' do
        original_hash = {:a => 1, :b => 2, :c => 0}

        message = Message.new(original_hash)

        message[:a] = 666
        message.delete :b
        message[:z] = 999

        message[:a].should ==(666)
        message[:b].should be_nil
        message[:c].should ==(original_hash[:c])
        message[:z].should ==(999)      
      end

      it 'can be merged with a map, symbolising keys' do
        original = Message.new({'a' => 1})
        original.merge!({'b' => 2})

        original[:a].should ==(1)
        original[:b].should ==(2)
      end
    end

    context 'message status' do

      let (:handler_that_should_never_be_called) { lambda { raise 'This shouldnt happen'  } }

      it 'doesnt do anything if no state callback specified' do
        Message.new.consumed!
        Message.new.rejected!
        Message.new.broken!        
      end

      it 'is possible to reject a message if broken'do
        called = []
        
        message = Message.new        
        message.on_broken  do |msg|
          called << msg
        end
        
        message.on_rejected(handler_that_should_never_be_called) 
        message.on_consumed(handler_that_should_never_be_called)

        message.broken!
        
        called.should==([message])
      end
      
      it 'is possible to reject a message if consumer cant handle it' do
        called = []
        
        message = Message.new        
        message.on_rejected  do |msg|
          called << msg
        end
        
        message.on_broken(handler_that_should_never_be_called)
        message.on_consumed(handler_that_should_never_be_called)

        message.rejected!
        
        called.should==([message])
      end

      it 'is possible to mark a message as consumed' do
        called = []
        
        message = Message.new        
        message.on_consumed do |msg|
          called << msg
        end
        
        message.on_broken(handler_that_should_never_be_called)
        message.on_rejected(handler_that_should_never_be_called)

        message.consumed!
        
        called.should==([message])
      end
      
      it 'is not possible to change a message after marking as consumed or rejected' do
        read = lambda { |m| m[:some_key] }
        mutate = lambda { |m| m[:some_key] = :some_value }
        
        consumed = Message.new
        consumed.consumed!
        
        rejected = Message.new
        rejected.rejected!
        
        broken = Message.new
        broken.broken!

        lambda{ read.call(consumed) }.should_not raise_error
        lambda{ mutate.call(consumed) }.should raise_error
        lambda{ read.call(rejected) }.should_not raise_error
        lambda{ mutate.call(rejected) }.should raise_error
        lambda{ read.call(broken) }.should_not raise_error
        lambda{ mutate.call(broken) }.should raise_error
      end
    end

    context 'forking messages for different handlers' do
      it 'forks a message with equal initial state' do
        origin = Message.new({:a => 1})
        fork = origin.fork

        origin.as_hash.should ==(fork.as_hash)
      end

      it 'forks a message with equal handlers' do
        origin = Message.new({:a => 1})

        consumed = []
        rejected = []
        broken   = []

        origin.on_consumed { |m| consumed << m}
        origin.on_rejected { |m| rejected << m}
        origin.on_broken   { |m| broken   << m}

        fork1 = origin.fork
        fork2 = origin.fork

        origin.consumed!
        fork1.broken!
        fork2.rejected!

        consumed.should ==([origin])
        rejected.should ==([fork2])
        broken.should   ==([fork1])
      end

      it 'makes the messages contents independent' do
        origin = Message.new({:a => 1})
        fork = origin.fork
        origin[:b] = 2
        fork[:c] = 3

        origin[:c].should be_nil
        fork[:c].should_not be_nil

        origin[:b].should_not be_nil
        fork[:b].should be_nil
      end

      it 'makes the messages state independent' do
        origin = Message.new({:a => 1})
        fork = origin.fork


        origin.broken!
        fork.consumed!

        origin.state.should ==(:broken)
        fork.state.should ==(:consumed)
      end
    end

    context 'generating a correlation id' do
      it 'creates a different CoId for each sequential message' do
        m1, m2, m3 = Message.new, Message.new, Message.new

        m1.co_id.should_not ==(m2.co_id)
        m1.co_id.should_not ==(m3.co_id)
        m2.co_id.should_not ==(m1.co_id)
        m2.co_id.should_not ==(m3.co_id)
        m3.co_id.should_not ==(m2.co_id)
        m3.co_id.should_not ==(m1.co_id)
      end

      it 'includes the process id on CoId so that multiple instances have different ids' do
        Message.new.co_id.should match(/#{Process.pid}/)
      end

      it 'does not change CoId with state chages' do
        m = Message.new
        old_id = m.co_id

        m.merge!({:some => :thing})
        merged_id = m.co_id

        m.consumed!
        consumed_id = m.co_id

        [merged_id, consumed_id].should ==([old_id, old_id])
      end

      it 'a forked message has a different, yet related, CoId from its origin' do
        origin = Message.new
        forked = origin.fork
        grandforked = forked.fork

        origin.co_id.should_not ==(forked.co_id)
        origin.co_id.should_not ==(grandforked.co_id)
        forked.co_id.should_not ==(grandforked.co_id)

        forked.co_id.should match(/#{origin.co_id}/)
        grandforked.co_id.should match(/#{forked.co_id}/)
      end
    end
  end
end

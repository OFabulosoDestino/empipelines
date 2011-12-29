module EmPipelines
  class Message
    attr_reader :state, :co_id

    @@count = 0
    
    def initialize(base_hash={})
      create_correlation_id!
      backing_hash!(base_hash)
      created!
    end

    def [](key)
      as_hash[key]
    end

    def []=(key, value)
      check_if_mutation_allowed
      as_hash[key] = value
    end

    def delete(key)
      check_if_mutation_allowed
      as_hash.delete key
    end

    def merge!(other_hash)
      check_if_mutation_allowed
      backing_hash!(as_hash.merge(other_hash))
      self
    end

    def on_consumed(callback=nil, &callback_block)
      @consumed_callback = block_given? ? callback_block : callback
    end

    def on_rejected(callback=nil, &callback_block)
      @rejected_callback = block_given? ? callback_block : callback
    end
    
    def on_rejected_broken(callback=nil, &callback_block)
      @rejected_broken_callback = block_given? ? callback_block : callback
    end

    def consumed!
      check_if_mutation_allowed
      @state = :consumed
      invoke(@consumed_callback)
    end

    def rejected!
      check_if_mutation_allowed
      @state = :rejected
      invoke(@rejected_callback)
    end
    
    def broken!
      check_if_mutation_allowed
      @state = :rejected_broken
      invoke(@rejected_broken_callback)
    end

    def as_hash
      @backing_hash
    end

    def payload
      as_hash[:payload]
    end
    
    def to_s
      "#{self.class.name} state:#{@state} backing_hash:#{as_hash}"
    end

    private
    def create_correlation_id!
      @@count += 1
      @co_id = "#{@@count}@#{Process.pid}"
    end

    def backing_hash!(other)
      @backing_hash = symbolised(other)
    end
    
    def symbolised(raw_hash)
      raw_hash.reduce({}) do |acc, (key, value)|
        acc[key.to_s.to_sym] = value.is_a?(Hash) ? symbolised(value) : value        
        acc
      end
    end

    def created!
      @state = :created
    end
    
    def check_if_mutation_allowed
      raise "Cannot mutate #{self}" unless @state == :created
    end
    
    def invoke(callback)
      callback.call(self) if callback
    end
  end
end

module Pipelines
  class Message
    def initialize(base_hash={})
      hash!(base_hash)
      created!
    end

    def [](key)
      hash[key]
    end

    def []=(key, value)
      check_if_mutation_allowed
      hash[key] = value
    end

    def delete(key)
      check_if_mutation_allowed
      hash.delete key
    end

    def merge(other_hash)
      check_if_mutation_allowed
      Message.new(hash.merge(other_hash))
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

    def hash
      @backing_hash
    end
    
    def to_s
      "#{self.class.name} state:#{@state} hash:#{hash}"
    end

    private

    def hash!(other)
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

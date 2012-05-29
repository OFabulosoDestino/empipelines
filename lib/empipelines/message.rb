module EmPipelines
  class Message
    attr_reader :state, :co_id

    @@count = 0

    def initialize(base_hash={}, origin=nil)
      @origin = origin
      create_correlation_id!
      backing_hash!(base_hash)
      created!
    end

    def [](key)
      to_hash[key]
    end

    def []=(key, value)
      check_if_mutation_allowed
      to_hash[key] = value
    end

    def delete(key)
      check_if_mutation_allowed
      to_hash.delete key
    end

    def merge!(other_hash)
      check_if_mutation_allowed
      backing_hash!(to_hash.merge(other_hash))
      self
    end

    def on_consumed(callback=nil, &callback_block)
      @consumed_callback = (callback || callback_block)
    end

    def on_rejected(callback=nil, &callback_block)
      @rejected_callback = (callback || callback_block)
    end

    def on_broken(callback=nil, &callback_block)
      @broken_callback = (callback || callback_block)
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
      @state = :broken
      invoke(@broken_callback)
    end

    def processed?
      @state != :created
    end

    def to_hash
      @backing_hash
    end

    def payload
      to_hash[:payload]
    end

    def copy
      forked = Message.new(to_hash, self)
      forked.on_broken(@broken_callback)
      forked.on_rejected(@rejected_callback)
      forked.on_consumed(@consumed_callback)
      forked
    end

    def to_s
      "#{self.class.name} co_id:#{co_id} state:#{@state} backing_hash:#{to_hash}"
    end

    private
    def create_correlation_id!
      @@count += 1
      suffix = @origin.nil? ? "@#{Process.pid}" : @origin.co_id
      @co_id = "#{@@count}@#{suffix}"
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
      raise "Cannot mutate #{self}" if processed?
    end

    def invoke(callback)
      callback.call(self) if callback
    end
  end
end

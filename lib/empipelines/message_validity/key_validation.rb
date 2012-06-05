module EmPipelines::MessageValidity
  class KeyValidation
    attr_accessor :keys, :error_text, :in, :proc

    def initialize(keys, top_level_key=nil)
      self.in = top_level_key
      self.keys = keys
    end

    # TODO: shouldn't we be able to have Set properties
    # without overloading `#eql?` and `#hash`?

    def eql?(other)
      self.class.name == other.class.name &&
      self.keys == other.keys &&
      self.in == other.in
    end

    def hash
      [ self.class.name, keys, self.in ].hash
    end
  end
end

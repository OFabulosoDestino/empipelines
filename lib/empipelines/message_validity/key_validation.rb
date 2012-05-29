module EmPipelines::MessageValidity
  class KeyValidation
    attr_accessor :keys, :error_text, :in, :proc

    class ImplementInSubclassError < NotImplementedError
      def initialize
        super("Implement in subclasses")
      end
    end

    def self.proc
      raise ImplementInSubclassError.new
    end

    def self.error_text
      raise ImplementInSubclassError.new
    end

    def self.declaration
      raise ImplementInSubclassError.new
    end

    def initialize(keys, top_level_key=:payload)
      self.in = top_level_key
      self.keys = keys
    end

    def eql?(other)
      # TODO: maintain Set properties
      # without overriding #eql? and #hash
      self.class.name == other.class.name &&
      self.keys == other.keys &&
      self.in == other.in
    end

    def hash
      [ self.class.name, keys, self.in ].hash
    end
  end
end

# encoding: utf-8
module EmPipelines::MessageValidity
  class KeyValidation
    attr_accessor :keys, :error_text, :in, :proc

    # this class is explicitly abstract™
    class ImplementInSubclassError < NotImplementedError
      def initialize
        super("Implement in subclasses")
      end
    end

    # a unary function to validate each datum
    #
    # e.g. `-> (x) { x.nil? }`
    #
    def self.proc
      raise ImplementInSubclassError.new
    end

    # what to say when validation fails
    #
    # e.g. `"yo, shit was nil"`
    #
    def self.error_text
      raise ImplementInSubclassError.new
    end

    # how this validation will be declared
    #
    # e.g. `:validates_not_nil`
    #
    def self.declaration
      raise ImplementInSubclassError.new
    end

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

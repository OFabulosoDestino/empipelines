module EmPipelines
  class Stage
    def initialize(services={})
      define_instance_variables(services)
    end

    def call(message, &callback)
      callback.call(message)
    end

  protected
    def define_instance_variables(services)
      services.each do |k,v|
        raise ArgumentError.new("invalid service definition") unless k
        self.class.__send__(:attr_accessor, k)

        self.instance_variable_set(:"@#{k.to_s}", v)
      end
    end
  end
end

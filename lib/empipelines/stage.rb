module EmPipelines
  class Stage
    attr_accessor :monitoring

    def initialize(monitoring)
      @monitoring = monitoring
    end
  end
end

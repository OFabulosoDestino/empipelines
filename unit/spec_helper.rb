module EmPipelines
  class MockMonitoring
    def self.error(text)
      text
    end
    def self.debug(text)
      text
    end
  end
end

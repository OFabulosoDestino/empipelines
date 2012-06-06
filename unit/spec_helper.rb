module EmPipelines
  class MockLogging
    def self.error(text)
      text
    end
    def self.debug(text)
      text
    end
  end
end

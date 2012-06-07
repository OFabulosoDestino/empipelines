require "logger"
require "devnull"

def mock_logging(output = false)
  Logger.new(output ? $stdout : DevNull.new )
end

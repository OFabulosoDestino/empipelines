module EmPipelines
  VERSION = '0.2.1'
end

require 'empipelines/event_handlers'
require 'empipelines/amqp_event_source'
require 'empipelines/batch_event_source'
require 'empipelines/io_event_source'
require 'empipelines/event_pipeline'
require 'empipelines/list_event_source'
require 'empipelines/message'
require 'empipelines/periodic_event_source'
require 'empipelines/pipeline'

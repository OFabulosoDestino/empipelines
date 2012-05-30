module EmPipelines
  VERSION = '0.3.0'
end

require 'empipelines/message'

require 'empipelines/message_validity'
require 'empipelines/stage'
require 'empipelines/event_source'
require 'empipelines/amqp_event_source'
require 'empipelines/batch_event_source'
require 'empipelines/io_event_source'
require 'empipelines/periodic_event_source'
require 'empipelines/aggregated_event_source'

require 'empipelines/event_pipeline'
require 'empipelines/pipeline'

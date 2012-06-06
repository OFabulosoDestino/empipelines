module EmPipelines
  VERSION = '0.3.1'
end

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'empipelines/message'

require 'empipelines/event_source'
require 'empipelines/event_sources/amqp_event_source'
require 'empipelines/event_sources/batch_event_source'
require 'empipelines/event_sources/io_event_source'
require 'empipelines/event_sources/periodic_event_source'
require 'empipelines/event_sources/aggregated_event_source'

require 'empipelines/event_pipeline'
require 'empipelines/pipeline'

require 'empipelines/stage'

require 'empipelines/message_validity'

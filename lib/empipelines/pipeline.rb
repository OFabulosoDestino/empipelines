module EmPipelines
  class Pipeline
    class TerminatorStage
      def self.notify(ignored, also_ignored = {})
        #noop
      end
    end
    
    def initialize(em, context, monitoring, logger)
      @em = em
      @logger = logger
      @context = context
      @monitoring = monitoring
    end
    
    def for(event_definition)
      stages = event_definition.map(&instantiate_with_dependencies)

      monitoring = @monitoring
      logger = @logger
      
      first_stage_process = stages.reverse.reduce(TerminatorStage) do |current_head, next_stage|
        @em.spawn do |input|
          begin
            logger.debug "#{next_stage.class}#notify with #{input}}"
            next_stage.call(input) do |output|
              current_head.notify(output)
            end
          rescue => exception
            monitoring.inform_exception!(exception, next_stage)
          end
        end        
      end
      
      @logger.info "Pipeline for event_definition is: #{stages.map(&:class).join('->')}"    
      first_stage_process
    end
    
    private
    def instantiate_with_dependencies
      lambda do |stage_class|
        stage_instance = stage_class.new
        @context.each do |name, value|
          stage_instance.define_singleton_method(name) { value }
        end
        stage_instance
      end
    end
  end
end

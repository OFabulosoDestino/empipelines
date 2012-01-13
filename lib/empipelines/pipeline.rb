module EmPipelines
  class Pipeline
    class TerminatorStage
      def self.notify(message, ignored = {})
        message.consumed!
      end
    end

    def initialize(em, context, monitoring)
      @em = em
      @context = context
      @monitoring = monitoring
    end

    def for(event_definition)
      stages = event_definition.map(&instantiate_with_dependencies)

      monitoring = @monitoring

      first_stage_process = stages.reverse.reduce(TerminatorStage) do |current_head, next_stage|
        @em.spawn do |input_message|
          begin
            monitoring.debug "#{next_stage.class}#notify with #{input_message}}"
            next_stage.call(input_message) do |output|
              current_head.notify(output)
            end
          rescue => exception
            monitoring.inform_exception!(exception, next_stage, "Message #{input_message} is broken")
            input_message.broken!
          end
        end
      end
      @monitoring.inform "Pipeline for event_definition is: #{stages.map(&:class).join('->')}"
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

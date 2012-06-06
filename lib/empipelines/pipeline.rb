module EmPipelines
  class Pipeline
    attr_accessor :em, :services, :stages

    class TerminatorStage
      def self.notify(message, ignored = {})
        message.consumed!
      end
    end

    def initialize(em, services)
      @em = em
      @services = services
    end

    # Pipeline#for(stages : Array<EmPipelines::Stage>)
    #
    # For each stage in the process chain:
    # - Instantiates that stage, passing its initialize method a hash of all services
    # - Spawns a process that, on each input_message:
    #   - invokes `call` on the next stage in the process chain and, as a callback:
    #     - invokes `notify` on the current head of the process chain
    #
    # Returns: the initial stage's spawned process

    def for(stages)
      @stages = stages.map { |stage| instantiate_stage_with_services(stage, services) }
      monitoring = services[:monitoring]

      first_stage_process = @stages.reverse.reduce(TerminatorStage) do |current_head, next_stage|
        @em.spawn do |input_message|
          begin
            monitoring.debug "#{next_stage.class}#notify with #{input_message}}"
            next_stage.call(input_message) do |output|
              current_head.notify(output)
            end
          rescue => exception # TODO: Really? all of them?
            monitoring.inform_exception!(exception, next_stage, "Message #{input_message} is broken")
            input_message.broken!
          end
        end
      end

      monitoring.inform "Pipeline for event_definition is: #{@stages.map(&:class).join('->')}"
      first_stage_process
    end

    protected
    def instantiate_stage_with_services(stage, services)
      stage.new(services)
    end
  end
end

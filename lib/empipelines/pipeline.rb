module EmPipelines
  class Pipeline
    attr_accessor :em, :services, :stages

    HALT_STATES = [ :consumed, :broken, :rejected ]

    class TerminatorStage
      def self.notify(message, ignored = {})
        message.consumed!
      end
    end

    # TODO: pass & instantiate stages only during #initialize
    # why have multiple initialization phases? ...arity-weirdness...
    # Two-argument version of #initialize should be considered deprecated.

    def initialize(em, services, stage_array=nil)
      @em = em
      @services = services
      @stages = instantiate_stages_with_services(stage_array, services) if stage_array
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

    def for(stage_array=nil)
      @stages = instantiate_stages_with_services(stage_array, services) if stage_array

      services[:logging].info "Pipeline: #{stages.map(&:class).join('->')}"

      monitoring_with_bindings = ->(message, stage) { monitor_state(message, stage) }
      propagation_with_bindings = ->(message, head, stage) { propagate_or_halt(message, head, stage) }

      stages.reverse.reduce(TerminatorStage) do |current_head, next_stage|
        @em.spawn do |input_message|
          # monitor_state(input_message, next_stage)
          # propagate_or_halt(input_message, current_head, next_stage)
          monitoring_with_bindings[input_message, next_stage]
          propagation_with_bindings[input_message, current_head, next_stage]
        end
      end
    end

  protected
    def instantiate_stages_with_services(stages, services)
      stages.map{ |stage| stage.new(services) }
    end

  private
    def propagate_or_halt(message, current_head, next_stage)
      if HALT_STATES.include?(message.state)
        services[:logging].info "Pipeline: stopping propagation."
      else
       next_stage.call(message) do |output|
          current_head.notify(output)
        end
      end
    end

    def monitor_state(message, next_stage)
      case message.state
      when :consumed
        services[:logging].info "Pipeline: Message #{message.state}."
      when :broken
        services[:logging].error "Pipeline: Message #{message.state}! next stage: #{next_stage.class.name}, message: #{message}"
      when :rejected
        services[:logging].error  "Pipeline: Message #{message.state}. next stage: #{next_stage.class.name}, message: #{message}"
      when :created
        services[:logging].info "Pipeline: Message #{message.state}. next stage: #{next_stage.class}, message: #{message}}"
      else
        services[:logging].warn "Pipeline: Message state is #{message.state}. This is an unrecognized state! next stage: #{next_stage.class.name}, message: #{message}"
      end
    end
  end
end

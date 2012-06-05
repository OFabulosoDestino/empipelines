require "active_support/core_ext/object/try"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/class/attribute_accessors"
require "empipelines/message_validity/key_validations/presence"
require "empipelines/message_validity/key_validations/temporality"
require "empipelines/message_validity/key_validations/numericality"
require "set"

module EmPipelines::MessageValidity
  def self.extended(base)
    base.cattr_accessor :validations
    base.validations ||= Set.new

    base.send(:include, InstanceInterface)
  end

  [ Presence, Numericality, Temporality ].each do |validation|
    send(:define_method, validation.declaration) do |*args|
      # TODO: extract 'in' argument without using `last`
      top_level_key =
        if (in_hash = args.last).is_a?(Hash)
          args.delete(in_hash)[:in].try(:to_sym)
        else
          nil
        end

      keys = args.uniq.compact
      raise ArgumentError.new("no keys specified for validation") if keys.blank?
      validations.add validation.new(*[keys, top_level_key].compact)
    end
  end

  def validate!(message, monitoring)
    failures = []

    validations.each do |validation|
      monitoring.debug "MessageValidity.validate! running validation: #{validation.class.name}"

      proc          = validation.class.proc
      keys          = validation.keys
      error_text    = validation.class.error_text
      target_hash   = (message[:payload][validation.in] || message[:payload]).to_hash

      keys.each do |key|
        unless proc.call(target_hash[key])
          failure = {
            :error_text => error_text,
            :key        => key,
            :value      => target_hash[key],
          }

          failures << failure
        end
      end
    end

    if failures.empty?
      true
    else
      failures.each do |failure|
        monitoring.error "#{failure[:error_text]}: #{ {failure[:key] => failure[:value]} }"
      end
      false
    end
  end

  module InstanceInterface
    def validate!(message)
      self.class.validate!(message, monitoring)
    end
  end
end

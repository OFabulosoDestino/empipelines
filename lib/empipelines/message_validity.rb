require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/core_ext/class/attribute_accessors"
require "empipelines/message_validity/key_validations/presence"
require "empipelines/message_validity/key_validations/temporality"
require "empipelines/message_validity/key_validations/numericality"
require "set"

module EmPipelines::MessageValidity
  def self.included(base)
    base.cattr_accessor :validations

    base.validations ||= Set.new

    base.extend ClassMethods
  end

  # TODO: rewrite into self.included
  module ClassMethods
    [ Presence, Numericality, Temporality ].each do |validation|
      method_name = validation.declaration
      send(:define_method, method_name) do |*keys|
        top_level_key = nil
        keys.delete_if do |arg|
          arg.is_a?(Hash) && top_level_key = arg[:in].try(:to_sym)
        end
        keys = keys.flatten.uniq.compact
        raise ArgumentError.new("no keys specified for validation") if keys.blank?

        validations.add validation.new(*[keys, top_level_key].compact)
      end
    end

    def validate!(message)
      self.validations.all? do |validation|
        proc          = validation.proc
        top_level_key = validation.in
        keys          = validation.keys
        error_text    = validation.error_text

        message[top_level_key].values_at(*keys).all?(&proc).tap do |result|
          monitoring.inform_error! "payload validation failed: #{error_text}" unless result
        end
      end || message.broken!
    end
  end
end

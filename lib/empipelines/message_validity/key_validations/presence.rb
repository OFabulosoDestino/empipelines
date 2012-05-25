require "empipelines/message_validity/key_validation"

module MessageValidity
  class Presence < KeyValidation
    def self.proc
      ->(x) { x.present? }
    end

    def self.error_text
      "required keys were not found in message"
    end

    def self.declaration
      :validates_presence_of_keys
    end
  end
end

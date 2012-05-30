require "empipelines/message_validity/key_validation"

module EmPipelines::MessageValidity
  class Numericality < KeyValidation
    def self.proc
      ->(x) do
        begin
          !!Float(x)
        rescue ArgumentError, TypeError
          false
        end
      end
    end

    def self.error_text
      "values required to be numeric weren't"
    end

    def self.declaration
      :validates_numericality_of_keys
    end
  end
end

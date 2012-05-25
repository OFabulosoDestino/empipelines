require "empipelines/message_validity/key_validation"

module MessageValidity
  class TemporalityValidation < KeyValidation
    def self.proc
      ->(x) do
        begin
          # TODO: determine if x is "parseable"
          # without relying on exceptions to modify control flow
          !!Time.parse(x)
        rescue ArgumentError, TypeError
          false
        end
      end
    end

    def self.error_text
      "values required to be be parsed as Time couldn't be"
    end

    def self.declaration
      :validates_temporality_of_keys
    end
  end
end

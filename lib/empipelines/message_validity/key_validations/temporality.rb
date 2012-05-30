require "empipelines/message_validity/key_validation"
require "time"

module EmPipelines::MessageValidity
  class Temporality < KeyValidation
    def self.proc
      ->(x) do
        begin
          if x.respond_to?(:to_time)
            !!x.to_time
          else
            !!Time.parse(x)
          end
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

require "empipelines/message"
require "empipelines/message_validity"
require "empipelines/message_validity/key_validations/numericality"

module EmPipelines::MessageValidity
  describe Numericality do
    it_behaves_like "KeyValidation subclass"

    let(:validation) { described_class.new([:foo]) }

    context "#proc" do
      context "with a valid data set" do
        let(:test_values) { [ "1", 100.0, ".0", 1 ] }

        it "returns true when mapped over the array" do
          test_values.all?(&(validation.proc)).should be_true
        end
      end

      context "with an invalid data set" do
        let(:test_values) { [ "1", 100.0, ".0", nil, "1.o" ] }

        it "returns false when mapped over the array" do
          test_values.all?(&(validation.proc)).should be_false
        end
      end
    end
  end
end

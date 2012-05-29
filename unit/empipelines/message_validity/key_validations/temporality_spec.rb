require "empipelines/message"
require "empipelines/message_validity"
require "empipelines/message_validity/key_validations/temporality"

module EmPipelines::MessageValidity
  describe Temporality do
    it_behaves_like "KeyValidation subclass"

    let(:validation) { described_class.new([:foo]) }

    context "#proc" do
      context "with a valid data set" do
        let(:test_values) { [ Time.new.to_s, Time.new, "19:19", ] }

        it "returns true when mapped over the array" do
          test_values.all?(&(validation.proc)).should be_true
        end
      end

      context "with an invalid data set" do
        let(:test_values) { [ Time.new.to_i, "foo", nil, "", ] }

        it "returns false when mapped over the array" do
          test_values.all?(&(validation.proc)).should be_false
        end
      end
    end
  end
end

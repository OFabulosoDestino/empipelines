require "empipelines/message"
require "empipelines/message_validity"
require "empipelines/message_validity/key_validations/presence"

module EmPipelines::MessageValidity
  describe Presence do
    it_behaves_like "KeyValidation subclass"

    context "#proc" do
      context "with a valid data set" do
        let(:test_values) { [ "foo", :a, :b, ] }

        it "returns true when mapped over the array" do
          test_values.all?(&(described_class.proc)).should be_true
        end
      end

      context "with an invalid data set" do
        let(:test_values) { [ "foo", :a, nil, :b, "", ] }

        it "returns false when mapped over the array" do
          test_values.all?(&(described_class.proc)).should be_false
        end
      end
    end
  end
end

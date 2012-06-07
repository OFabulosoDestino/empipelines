require "empipelines"

module EmPipelines::MessageValidity
  describe KeyValidation do
    let(:em) { mock("eventmachine") }
    let(:logging) { mock("logging") }
    let(:services) { { logging: logging } }

    shared_examples_for "KeyValidation subclass" do
      context "two KeyValidation objects with identical `class.name`, `keys`, and `in` properties" do
        let(:v1) { described_class.new([:a, :b, :c], :in => :top_level_key) }
        let(:v2) { described_class.new([:a, :b, :c], :in => :top_level_key) }

        context "#eql?" do
          it "returns true" do
            v1.eql?(v2).should be_true
          end

          context "and different `error_text` properties" do
            before { v1.error_text = "random text" }

            it "returns true" do
              v1.eql?(v2).should be_true
            end
          end
        end

        context "#hash" do
          it "should hash identically" do
            v1.hash.should == v2.hash
          end
        end
      end
    end

    context "#initialize" do
      it "initializes without error when given keys" do
        expect do
          KeyValidation.new(:keys => [:a, :b, :c])
        end.to_not raise_error
      end

      it "raises an argument error without keys" do
        expect do
          KeyValidation.new
        end.to raise_error(ArgumentError)
      end

      it "initializes without error when given `keys` values" do
        expect do
          KeyValidation.new(:keys => [:a, :b, :c])
        end.to_not raise_error
      end
    end

    context ".proc" do
      it "should raise a NoMethodError error if instantiated directly" do
        expect do
          KeyValidation.proc
        end.to raise_error(NoMethodError)
      end
    end

    context ".error_text" do
      it "should raise a NoMethodError error if instantiated directly" do
        expect do
          KeyValidation.error_text
        end.to raise_error(NoMethodError)
      end
    end

    context ".declaration" do
      it "should raise a NoMethodError error if instantiated directly" do
        expect do
          KeyValidation.declaration
        end.to raise_error(NoMethodError)
      end
    end
  end

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

  describe Numericality do
    it_behaves_like "KeyValidation subclass"

    context "#proc" do
      context "with a valid data set" do
        let(:test_values) { [ "1", 100.0, ".0", 1 ] }

        it "returns true when mapped over the array" do
          test_values.all?(&(described_class.proc)).should be_true
        end
      end

      context "with an invalid data set" do
        let(:test_values) { [ "1", 100.0, ".0", nil, "1.o" ] }

        it "returns false when mapped over the array" do
          test_values.all?(&(described_class.proc)).should be_false
        end
      end
    end
  end

  describe Temporality do
    it_behaves_like "KeyValidation subclass"

    context "#proc" do
      context "with a valid data set" do
        let(:test_values) { [ Time.new.to_s, Time.new, "19:19", ] }

        it "returns true when mapped over the array" do
          test_values.all?(&(described_class.proc)).should be_true
        end
      end

      context "with an invalid data set" do
        let(:test_values) { [ Time.new.to_i, "foo", nil, "", ] }

        it "returns false when mapped over the array" do
          test_values.all?(&(described_class.proc)).should be_false
        end
      end
    end
  end
end

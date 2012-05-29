require "empipelines/message"
require "empipelines/message_validity"
require "empipelines/message_validity/key_validations/presence"

module EmPipelines
  describe MessageValidity do
    let(:em) { mock("eventmachine") }
    let(:monitoring) { mock("monitoring") }
    let(:test_class) do
      class TestStage
        class FakeMonitoring
          def self.inform_error!(text)
            text
          end
        end

        cattr_accessor :monitoring
        @@monitoring = FakeMonitoring
      end

      TestStage
    end

    def inject_module_into(klass)
      "include #{described_class}".tap { |s| klass.class_eval(s) }
    end

    def define_validation(klass, proc)
      klass.class_exec &proc
    end

    # TODO: this shouldn't be needed
    def reset_attrs!(klass)
      klass.validations = Set.new
    end

    before do
      inject_module_into test_class
      reset_attrs! test_class
    end

    context "method injection" do
      it "[meta] makes sense" do
        test_class.class.should == Class
      end

      context "#validates_presence_of_keys" do
        it "injects the method on module inclusion" do
          test_class.should respond_to(:validates_presence_of_keys)
        end
      end

      context "#validate!" do
        it "injects the method on module inclusion" do
          test_class.should respond_to(:validate!)
        end
      end
    end

    context "method definition" do
      context "#validates_presence_of_keys" do
        it "runs the injected method on the class" do
          expect do
            define_validation(test_class, -> { validates_presence_of_keys :a })
          end.to_not raise_error
        end
      end

      context "argument parsing" do
        context "error handling" do
          it "fails loud & hard if there are no key arguments" do
            expect do
              define_validation(test_class, -> { validates_presence_of_keys })
            end.to raise_error(ArgumentError)
          end
        end

        context "#in (aka top_level_key)" do
          it "defaults to nil" do
            define_validation(test_class, -> { validates_presence_of_keys :a })

            test_class.validations.should include(EmPipelines::MessageValidity::Presence.new([:a], nil))
          end

          it "allows overrides" do
            define_validation(test_class, -> { validates_presence_of_keys :a, :in => :payload })

            test_class.validations.should include(EmPipelines::MessageValidity::Presence.new([:a], :payload))
          end

          it "shouldnt fall over if, for whatever reason, nil is specified explicitly" do
            define_validation(test_class, -> { validates_presence_of_keys :a, :in => nil })

            test_class.validations.should include(EmPipelines::MessageValidity::Presence.new([:a], nil))
          end
        end
      end

      context "@validations" do
        it "begins empty" do
          test_class.validations.size.should == 0
        end

        it "adds each defined validation to the list" do
          expect do
            define_validation(test_class, -> { validates_presence_of_keys :a })
          end.to change { test_class.validations.size }.by(1)
        end

        it "[meta] another identical example is idempotent" do
          expect do
            define_validation(test_class, -> { validates_presence_of_keys :a })
          end.to change { test_class.validations.size }.by(1)
        end

        it "ignores duplicate validation declarations" do
          expect do
            define_validation(test_class, -> { validates_presence_of_keys :a })
            define_validation(test_class, -> { validates_presence_of_keys :a })
            define_validation(test_class, -> { validates_presence_of_keys :a })
          end.to change { test_class.validations.size }.by(1)
        end
      end
    end

    context "#validate!" do
      context "with two presence requirements" do
        before do
          define_validation(test_class, -> { validates_presence_of_keys :a, :in => :payload })
          define_validation(test_class, -> { validates_presence_of_keys :a, :b, :in => :payload })
        end

        let(:valid_message) do
          original_hash = {
            payload: {
              a: "1",
              b: 2,
            }
          }

          Message.new(original_hash)
        end

        let(:invalid_message) do
          original_hash = {
            payload: {
              b: 2,
            }
          }

          Message.new(original_hash)
        end

        context "with a valid message" do
          let(:message) { valid_message }

          it "judges validity correctly" do
            test_class.validate!(message).should be_true
          end

          it "raises no errors" do
            expect do
              test_class.validate!(message)
            end.to_not raise_error
          end
        end

        context "with an invalid message" do
          let(:message) { invalid_message }

          it "judges validity correctly" do
            test_class.validate!(message).should be_false
          end

          it "notifies monitoring of errors" do
            test_class.monitoring.should_receive(:inform_error!).with(/payload validation failed/)

            test_class.validate!(message)
          end

          it "marks the message as broken" do
            message.should_receive(:broken!)

            test_class.validate!(message)
          end
        end
      end
    end
  end
end

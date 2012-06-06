require 'empipelines'
require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module EmPipelines
  describe MessageValidity do
    let(:em) { mock("eventmachine") }
    let(:logging) { MockLogging.new }
    let(:services) { { logging: logging } }
    let(:test_class) do
      class TestStage < EmPipelines::Stage; end

      TestStage
    end

    def inject_module_into(klass)
      klass.send(:extend, described_class)
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

    context "#initialize" do
      it "doesn't throw an error" do
        expect do
          test_class.new(services)
        end.to_not raise_error
      end

      it "calls super" do
        EmPipelines::Stage.should_receive(:new)

        test_class.new(services)
      end
    end

    context "method injection" do
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
            define_validation(test_class, -> { validates_presence_of_keys :a, :in => :foo })

            test_class.validations.should include(EmPipelines::MessageValidity::Presence.new([:a], :foo))
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
          define_validation(test_class, -> { validates_presence_of_keys :a, :in => :nest })
          define_validation(test_class, -> { validates_presence_of_keys :b, :in => :nest })
        end

        let(:valid_message) do
          original_hash = {
            payload: {
              nest: {
                a: "1",
                b: 2,
              }
            }
          }

          Message.new(original_hash)
        end

        let(:invalid_message_one) do
          original_hash = {
            payload: {
              nest: {
                b: "1",
                c: 2,
              }
            }
          }

          Message.new(original_hash)
        end

        let(:invalid_message_two) do
          original_hash = {
            payload: {
              nest: {
                c: 3,
              }
            }
          }

          Message.new(original_hash)
        end

        context "with a totally valid message" do
          let(:message) { valid_message }

          it "judges validity correctly" do
            logging.should_receive(:debug).any_number_of_times

            test_class.validate!(message, services).should be_true
          end

          it "raises no errors" do
            logging.should_not_receive(:error)
            logging.should_receive(:debug).any_number_of_times

            expect do
              test_class.validate!(message, services)
            end.to_not raise_error
          end
        end

        context "with a message failing one requirement" do
          let(:message) { invalid_message_one }

          it "judges validity correctly" do
            logging.should_receive(:error).once
            logging.should_receive(:debug).any_number_of_times

            test_class.validate!(message, services).should be_false
          end

          it "notifies logging of errors for each failing key" do
            logging.should_receive(:error).once
            logging.should_receive(:debug).any_number_of_times

            test_class.validate!(message, services)
          end
        end

        context "with a message failing both requirements" do
          let(:message) { invalid_message_two }

          it "judges validity correctly" do
            logging.should_receive(:error).twice
            logging.should_receive(:debug).any_number_of_times

            test_class.validate!(message, services).should be_false
          end

          it "notifies logging of errors for each failing key" do
            logging.should_receive(:error).twice
            logging.should_receive(:debug).any_number_of_times

            test_class.validate!(message, services)
          end
        end
      end
    end
  end
end

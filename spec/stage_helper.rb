def request(path = path)
  responses = []
  described_class.request(path) { |response| responses << response }
  responses
end

def process(message = message, stage_class = described_class)
  messages = []
  stage_instance = stage_class.new

  #TODO: should this be here? Is there an easy way?
  context.each {|k,v| stage_instance.define_singleton_method(k) {v} }

  stage_instance.call(message) { |message| messages << message }
  messages
end

RSpec::Matchers.define :return_response do |expected|
  match do |responses|
    responses.include?(expected)
  end
end

RSpec::Matchers.define :return_any_response do |expected|
  match do |responses|
    responses.any?
  end
end

RSpec::Matchers.define :send_messages_including do |expected|
  match do |messages|
    messages.any? do |message|
      expected.all? do |key, value|
        message[key] == value
      end
    end
  end
end

RSpec::Matchers.define :send_some_message do |expected|
  match do |messages|
    messages.any?
  end
end

RSpec::Matchers.define :send_no_message do |expected|
  match do |messages|
    messages.empty?
  end
end

RSpec::Matchers.define :send_message do |expected|
  match { |messages| messages.include?(expected) }
end

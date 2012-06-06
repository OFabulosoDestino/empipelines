Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'
  ## Leave these as is they will be modified for you by the rake gemspec task.
  s.name              = 'empipelines'
  s.version           = '0.3.1'
  s.date              = '2012-06-06'
  s.rubyforge_project = 'empipelines'

  s.summary           = "Simple Event Handling Pipeline Architecture for EventMachine"
  s.description       = "Simple Event Handling Pipeline Architecture for EventMachine"

  s.authors           = ["Tobias Schmidt", "Phil Calcado", "Patrick Ellis"]
  s.email             = 'phil+empipelines@soundcloud.com'
  s.homepage          = 'http://github.com/soundcloud/empipelines'

  s.require_paths = %w[lib]
  #s.executables = ["empipelines"]
  #s.default_executable = 'empipelines'

  ## Specify any RDoc options here.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md]

  ## List your runtime dependencies here.
  #s.add_dependency('DEPNAME', [">= 1.1.0", "< 2.0.0"])
  #s.add_development_dependency('bacon', [">= 1.1.0])
  #s.add_development_dependency('rspec', [">= 1.3.0"])

  ## DO NOT REMOVE THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    Gemfile.lock
    README.md
    Rakefile
    empipelines.gemspec
    functional/consuming_events_from_amqp_spec.rb
    functional/consuming_events_from_batch_spec.rb
    functional/consuming_events_from_file_spec.rb
    functional/consuming_events_from_multiple_sources_spec.rb
    functional/consuming_events_with_message_validation_spec.rb
    functional/events.dat
    functional/test_stages.rb
    lib/empipelines.rb
    lib/empipelines/event_pipeline.rb
    lib/empipelines/event_source.rb
    lib/empipelines/event_sources/aggregated_event_source.rb
    lib/empipelines/event_sources/amqp_event_source.rb
    lib/empipelines/event_sources/batch_event_source.rb
    lib/empipelines/event_sources/io_event_source.rb
    lib/empipelines/event_sources/periodic_event_source.rb
    lib/empipelines/message.rb
    lib/empipelines/message_validity.rb
    lib/empipelines/message_validity/key_validation.rb
    lib/empipelines/message_validity/key_validations/numericality.rb
    lib/empipelines/message_validity/key_validations/presence.rb
    lib/empipelines/message_validity/key_validations/temporality.rb
    lib/empipelines/pipeline.rb
    lib/empipelines/stage.rb
    unit/empipelines/event_pipeline_spec.rb
    unit/empipelines/event_source_spec.rb
    unit/empipelines/event_sources/aggregated_event_source_spec.rb
    unit/empipelines/event_sources/amqp_event_source_spec.rb
    unit/empipelines/event_sources/batch_event_source_spec.rb
    unit/empipelines/event_sources/empty_io_event_source.dat
    unit/empipelines/event_sources/io_event_source.dat
    unit/empipelines/event_sources/io_event_source_spec.rb
    unit/empipelines/event_sources/periodic_event_source_spec.rb
    unit/empipelines/message_spec.rb
    unit/empipelines/message_validity/key_validation_spec.rb
    unit/empipelines/message_validity/key_validations/numericality_spec.rb
    unit/empipelines/message_validity/key_validations/presence_spec.rb
    unit/empipelines/message_validity/key_validations/temporality_spec.rb
    unit/empipelines/message_validity_spec.rb
    unit/empipelines/pipeline_spec.rb
    unit/spec_helper.rb
    unit/stage_helper.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list.
  s.test_files = s.files.select { |path| path =~ /^spec\/*_spec\.rb/ }
end

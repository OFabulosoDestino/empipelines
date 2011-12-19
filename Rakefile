$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:non_wip_features) do |t|
  t.cucumber_opts = "--format pretty --tag ~@wip"
end

Cucumber::Rake::Task.new(:all_features) do |t|
  t.cucumber_opts = "--format pretty"
end

desc "Runs specs"
task :specs do
  all = FileList['spec/**/*_spec.rb']
  sh "rspec --color  #{all}"
end

desc "Resets localhost's rabbitmq"
task :reset_rabbitmq do
  sh 'rabbitmqctl stop_app'
  sh 'rabbitmqctl reset'
  sh 'rabbitmqctl start_app'
end

desc "Run cucumber tests for finished features"
task :features do

end

desc "Run cucumber tests for all features, including work in progress"
task :all_features do
  
end

task :ci => [:specs, :features]

desc "MUST BE RUN (AND PASS!) BEFORE CHECKING IN CODE!"
task :pre_checkin => [:reset_rabbitmq, :ci]

task :default => :pre_checkin

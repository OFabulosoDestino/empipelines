$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'cucumber/rake/task'
require 'rubygems'
require 'rake'
require 'date'

#############################################################################
#
# Helper functions
#
#############################################################################

def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def version
  line = File.read("lib/#{name}.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end

def date
  Date.today.to_s
end

def rubyforge_project
  name
end

def gemspec_file
  "#{name}.gemspec"
end

def gemspec
  @gemspec ||= eval(IO.read(gemspec_file))
end

def gem_file
  gemspec.file_name
end

def replace_header(head, header_name)
  head.sub!(/(\.#{header_name}\s*= ').*'/) { "#{$1}#{send(header_name)}'"}
end

#############################################################################
#
# Standard tasks
#
#############################################################################
task :default => :pre_checkin

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
  sh 'rabbitmqctl stop_app; echo 0'
  sh 'rabbitmqctl reset; echo 0'
  sh 'rabbitmqctl start_app'
end

desc "Run cucumber tests for finished features"
task :features do

end

desc "Run cucumber tests for all features, including work in progress"
task :all_features do
  
end

task :ci => [:specs, :features, :build]

desc "MUST BE RUN (AND PASS!) BEFORE CHECKING IN CODE!"
task :pre_checkin => [:reset_rabbitmq, :ci]

#############################################################################
#
# Custom tasks (add your own tasks here)
#
#############################################################################



#############################################################################
#
# Packaging tasks
#
#############################################################################

task :release => :ci do
  Dir.chdir File.dirname(__FILE__)
  unless `git branch` =~ /^\* master$/
    puts "You must be on the master branch to release!"
    exit!
  end
  if `git fetch --tags && git tag`.split(/\n/).include?(gem_file)
    raise "Version #{gem_file} already deployed"
  end
  sh <<-END
    git commit -a --allow-empty -m 'Release #{gem_file}'
    git tag -a #{gem_file} -m 'Version #{gem_file}'
    git push origin master
    git push origin --tags
  END
end

desc "Build #{gem_file} into the pkg directory"
task :build => :gemspec do
  sh "mkdir -p pkg"
  sh "gem build #{gemspec_file}"
  sh "mv #{gem_file} pkg"
end

desc "Generate #{gemspec_file}"
task :gemspec => :validate do
  # read spec file and split out manifest section
  spec = File.read(gemspec_file)
  head, manifest, tail = spec.split("  # = MANIFEST =\n")

  # replace name version and date
  replace_header(head, :name)
  replace_header(head, :version)
  replace_header(head, :date)
  #comment this out if your rubyforge_project has a different name
  replace_header(head, :rubyforge_project)

  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").
    sort.
    reject { |file| file =~ /^\./ }.
    reject { |file| file =~ /^(rdoc|pkg)/ }.
    map { |file| "    #{file}" }.
    join("\n")

  # piece file back together and write
  manifest = "  s.files = %w[\n#{files}\n  ]\n"
  spec = [head, manifest, tail].join("  # = MANIFEST =\n")
  File.open(gemspec_file, 'w') { |io| io.write(spec) }
  puts "Updated #{gemspec_file}"
end

desc "Validate #{gemspec_file}"
task :validate do
  libfiles = Dir['lib/*'] - ["lib/#{name}.rb", "lib/#{name}"]
  unless libfiles.empty?
    puts "Directory `lib` should only contain a `#{name}.rb` file and `#{name}` dir."
    exit!
  end
  unless Dir['VERSION*'].empty?
    puts "A `VERSION` file at root level violates Gem best practices."
    exit!
  end
end

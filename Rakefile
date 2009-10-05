require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "deployment_notifier"
    gem.summary = %Q{Deployment notifications for Capistrano}
    gem.description = %Q{A plugin for Capistrano to send an e-mail to notify people about deployments.}
    gem.email = "jon@blankpad.net"
    gem.homepage = "http://github.com/jellybob/deployment_notifier"
    gem.authors = ["Jon Wood"]
    gem.add_development_dependency "rspec"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

begin
  require 'spec/rake/spectask'

  desc "Run all specs"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.libs = [ 'lib' ]
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
  
  desc "Run all specs, with coverage"
  Spec::Rake::SpecTask.new('spec:coverage') do |t|
    t.libs = [ 'lib' ]
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec,osx\/objc,gems\/']
  end
rescue LoadError
  puts "RSpec and RCov are required to run tests. Install it with: sudo gem install rspec rcov"
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "deployment_notifier #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

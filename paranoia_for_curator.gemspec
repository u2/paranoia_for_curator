# -*- encoding: utf-8 -*-
require File.expand_path("../lib/paranoia_for_curator/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "paranoia_for_curator"
  s.version     = ParanoiaForCurator::VERSION
  s.licenses    = ['MIT']
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["zhangyaning1985@gmail.com"]
  s.email       = ["zhangyaning1985@gmail.com"]
  s.homepage    = "http://github.com/u2/paranoia_for_curator"
  s.summary     = "ParanoiaForCurator is a implementation of paranoid for curator."
  s.description = "ParanoiaForCurator is a implementation of paranoid for curator. You would use either plugin / gem if you wished that when you called destroy on a Curator object that it didn't actually destroy it, but just \"hid\" the record. ParanoiaForCurator does this by setting a deleted_at field to the current time when you destroy a record, and hides it by scoping all queries on your model to only include records which do not have a deleted_at field."

  s.add_dependency "curator", "~> 0.11.0"

  s.add_development_dependency 'bundler', '~> 1.10.6'
  s.add_development_dependency 'rake', '~> 10.5.0'
  s.add_development_dependency 'rspec', '~> 3.4.0'

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.test_files    = Dir['spec/**/*']
  s.require_path = 'lib'
end

# -*- encoding: utf-8 -*-

require './lib/watchman/version'

Gem::Specification.new do |s|
  s.name = %q{watchman}
  s.version = Watchman::VERSION.dup
  s.authors = ["Ivgeni Slabkovski"]
  s.email = %q{zhenya@zhenya.ca}
  s.license = "MIT"
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.files = Dir["**/*"] - Dir["*.gem"] - ["Gemfile.lock"]
  s.homepage = %q{http://github.com/hazah/watchman}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  #s.rubyforge_project = %q{watchman}
  s.rubygems_version = %q{0.0.1}
  s.summary = %q{Rack middleware that provides authorization for rack applications}
  s.add_dependency "rack", ">= 1.0"
end

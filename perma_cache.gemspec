# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'perma_cache/version'

Gem::Specification.new do |spec|
  spec.name          = "perma_cache"
  spec.version       = PermaCache::VERSION
  spec.authors       = ["Josh Sharpe"]
  spec.email         = ["josh.m.sharpe@gmail.com"]
  spec.description   = %q{It's a perma cache, duh}
  spec.summary       = %q{It's a perma cache, duh}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "debugger"
end


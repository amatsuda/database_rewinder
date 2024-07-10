# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "database_rewinder"
  spec.version       = '1.0.1'
  spec.authors       = ["Akira Matsuda"]
  spec.email         = ["ronnie@dio.jp"]
  spec.description   = "A minimalist's tiny and ultra-fast database cleaner for Active Record"
  spec.summary       = "A minimalist's tiny and ultra-fast database cleaner"
  spec.homepage      = 'https://github.com/amatsuda/database_rewinder'
  spec.license       = "MIT"

  spec.files         = `git ls-files lib/ MIT_LICENSE README.md`.split
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'test-unit-rails'
  spec.add_development_dependency 'rails'
  spec.required_ruby_version = '>= 2.0.0'
end

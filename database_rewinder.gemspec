# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'database_rewinder/version'

Gem::Specification.new do |spec|
  spec.name          = "database_rewinder"
  spec.version       = DatabaseRewinder::VERSION
  spec.authors       = ["Akira Matsuda"]
  spec.email         = ["ronnie@dio.jp"]
  spec.description   = "A minimalist's tiny and ultra-fast database cleaner"
  spec.summary       = "A minimalist's tiny and ultra-fast database cleaner"
  spec.homepage      = 'https://github.com/amatsuda/database_rewinder'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'sqlite3'
end

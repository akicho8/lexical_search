# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lexical_search/version'

Gem::Specification.new do |spec|
  spec.name          = "lexical_search"
  spec.version       = LexicalSearch::VERSION
  spec.authors       = ["akicho8"]
  spec.email         = ["akicho8@gmail.com"]
  spec.description   = %q{Google like search query parser for ActiveRecord}
  spec.summary       = %q{Google like search query parser for ActiveRecord}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  # for yard
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "yard-rspec"
  spec.add_development_dependency "yard-rubicle"
  spec.add_development_dependency "tapp"
  spec.add_development_dependency "pry"

  spec.add_dependency "activesupport", "< 4.0.0"
  spec.add_dependency "activerecord", "< 4.0.0"
  spec.add_dependency "sqlite3", "< 4.0.0"
end

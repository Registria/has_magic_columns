# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'has_magic_columns/version'

Gem::Specification.new do |s|
  s.name          = "has_magic_columns"
  s.version       = HasMagicColumns::VERSION
  s.authors       = ""
  s.email         = ""
  s.description   = %q{Magic Columns for Rails 5}
  s.summary       = %q{Rails 5+ compatible version of this gem - refactored using has_magic_fields gem as the base}
  s.homepage      = "https://github.com/registria/has_magic_columns"
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|s|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.16"
  s.add_development_dependency "rake"
  s.add_dependency("rails", [">= 5.0.0"])

end

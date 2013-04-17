# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mytrilogy/version'

Gem::Specification.new do |gem|
  gem.name          = "mytrilogy"
  gem.version       = Mytrilogy::VERSION
  gem.authors       = ["Grant Gongaware"]
  gem.email         = ["grant@telmate.com"]
  gem.description   = %q{mysql utils for migrations and stored procedures}
  gem.summary       = %q{mysql the trilogy gem for rails}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency "treetop", "~> 1.4.12"

end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'CLIntegracon/version'

Gem::Specification.new do |spec|
  spec.name          = "clintegracon"
  spec.version       = CLIntegracon::VERSION
  spec.authors       = ["Marius Rackwitz"]
  spec.email         = ["git@mariusrackwitz.de"]
  spec.homepage      = "https://github.com/mrackwitz/CLIntegracon"
  spec.license       = "MIT"

  spec.summary       = "Integration specs for your CLI"
  spec.description   = "CLIntegracon allows you to build Integration specs for your CLI,"  \
                       "independent if they are based on Ruby or another technology."      \
                       "It is especially useful if your command modifies the file system." \
                       "It provides an integration for Bacon."

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", '~> 10.1.0'   # Ruby 1.8.7
  spec.add_development_dependency "bacon"
  spec.add_development_dependency "mocha", "~> 1.0.0"   # Ruby 1.8.7
  spec.add_development_dependency "mocha-on-bacon"
  spec.add_development_dependency "claide"              # Example CLI
  spec.add_development_dependency "inch"

  spec.add_runtime_dependency 'colored', '~> 1.2'
  spec.add_runtime_dependency 'diffy'
end

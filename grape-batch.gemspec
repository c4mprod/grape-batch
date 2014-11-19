# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grape/batch/version'

Gem::Specification.new do |spec|
  spec.name          = 'grape-batch'
  spec.version       = Grape::Batch::VERSION
  spec.authors       = ['Lionel Oto', 'Vincent Falduto', 'Cédric Darné']
  spec.email         = ['lionel.oto@c4mprod.com', 'vincent.falduto@c4mprod.com', 'cedric.darne@c4mprod.com']
  spec.summary       = %q{Extends Grape::API to support request batching }
  spec.homepage      = 'https://github.com/c4mprod/grape-batch'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rack', '~> 1.5'
  spec.add_runtime_dependency 'grape', '~> 0.9.0'
  spec.add_runtime_dependency 'multi_json', '>= 1.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3.2'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'rack-test', '~> 0.6.2'
end

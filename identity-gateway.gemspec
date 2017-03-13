# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'identity/gateway/version'

Gem::Specification.new do |spec|
  spec.name          = 'identity-gateway'
  spec.version       = Identity::Gateway::VERSION
  spec.authors       = ['Loic Kartono']
  spec.email         = ['kartono.loic@gmail.com']

  spec.summary       = 'Identity\'s gateway provider'
  spec.description   = 'Identity\'s gateway provider for Ruby and Rails applications'
  spec.homepage      = 'https://github.com/wamland-team/identity-gateway'
  spec.license       = 'MIT'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'httparty', '~> 0.13'
  spec.add_development_dependency 'bundler', '~> 1.14.6', '>= 1.14.6'
  spec.add_development_dependency 'rake', '~> 11.3'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.47.1'
end

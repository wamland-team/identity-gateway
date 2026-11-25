# frozen_string_literal: true

require_relative 'lib/identity/gateway/version'

Gem::Specification.new do |spec|
  spec.name          = 'identity-gateway'
  spec.version       = Identity::Gateway::VERSION
  spec.authors       = ['Loic Kartono']
  spec.email         = ['kartono.loic@gmail.com']

  spec.summary       = 'Identity\'s gateway provider'
  spec.description   = 'Identity\'s gateway provider for Ruby and Rails applications'
  spec.homepage      = 'https://github.com/wamland-team/identity-gateway'
  spec.license       = 'MIT'

  spec.require_paths = ['lib']
  spec.files         = Dir['lib/**/*.rb', 'README.md', 'LICENSE.txt']

  spec.required_ruby_version = '>= 3.4'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'httparty', '~> 0.24'
end

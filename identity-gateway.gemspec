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

  spec.add_dependency 'httparty'
  spec.add_dependency 'activerecord'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 0.47.1'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'generator_spec'
end

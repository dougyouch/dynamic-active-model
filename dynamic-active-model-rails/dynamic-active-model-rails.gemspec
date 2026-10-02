# frozen_string_literal: true

# Versioned in lockstep with the core gem: release-please bumps one VERSION for both.
require_relative '../lib/dynamic-active-model/version'

Gem::Specification.new do |s|
  s.name        = 'dynamic-active-model-rails'
  s.version     = DynamicActiveModel::VERSION
  s.summary     = 'Rails integration for dynamic-active-model'
  s.description = 'Railtie for dynamic-active-model: declare databases in one initializer and get lazily ' \
                  'built, reloadable models in CarsDB-style namespaces, with extension files in ' \
                  'app/models/cars_db/ and automatic rebuilds after migrations.'
  s.licenses    = ['MIT']
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/dynamic-active-model/tree/master/dynamic-active-model-rails'
  s.files       = Dir.glob('lib/**/*.{rb,tt}') + ['README.md']
  s.required_ruby_version = '>= 3.2'

  s.add_dependency 'activerecord', '>= 7.1'
  s.add_dependency 'dynamic-active-model', DynamicActiveModel::VERSION
  s.add_dependency 'railties', '>= 7.1'
  s.metadata['rubygems_mfa_required'] = 'true'
end

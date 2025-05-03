# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'dynamic-active-model'
  s.version     = '0.6.2'
  s.summary     = 'Dynamic ActiveRecord Models'
  s.description = 'Dynamically create ActiveRecord models for tables'
  s.licenses    = ['MIT']
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/dynamic-active-model'
  s.files       = Dir.glob('lib/**/*.rb') + Dir.glob('bin/*')
  s.bindir      = 'bin'
  s.executables << 'dynamic-db-explorer'
  s.required_ruby_version = '>= 3.0'

  s.add_runtime_dependency 'activerecord', '>= 4'
  s.add_runtime_dependency 'inheritance-helper', '~> 0.2'
end

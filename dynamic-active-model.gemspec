# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'dynamic-active-model'
  s.version     = '0.1.0'
  s.summary     = 'Dynamic ActiveRecord Models'
  s.description = 'Dynamically create ActiveRecord models for tables'
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/dynamic-active-model'
  s.files       = Dir.glob('lib/**/*.rb') + Dir.glob('bin/*')
  s.bindir      = 'bin'

  s.add_runtime_dependency 'activerecord'
end

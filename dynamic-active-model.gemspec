# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'dynamic-active-model'
  s.version     = '0.7.1'
  s.summary     = 'Automatically discover database schemas and create ActiveRecord models with relationships'
  s.description = 'Dynamic Active Model automatically discovers database schemas and creates ActiveRecord ' \
                  'models without manual class definitions. It detects and configures relationships ' \
                  '(belongs_to, has_many, has_one, has_and_belongs_to_many) based on foreign keys and ' \
                  'constraints, handles dangerous attribute names, supports model extensions, and includes ' \
                  'a CLI tool for interactive database exploration.'
  s.licenses    = ['MIT']
  s.authors     = ['Doug Youch']
  s.email       = 'dougyouch@gmail.com'
  s.homepage    = 'https://github.com/dougyouch/dynamic-active-model'
  s.files       = Dir.glob('lib/**/*.rb') + Dir.glob('bin/*')
  s.bindir      = 'bin'
  s.executables << 'dynamic-db-explorer'
  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'activerecord', '>= 4'
  s.add_dependency 'inheritance-helper', '~> 0.2'
  s.metadata['rubygems_mfa_required'] = 'true'
end

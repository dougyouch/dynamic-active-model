# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in dynamic-active-model.gemspec
gemspec

group :development, :test do
  gem 'irb'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov', require: false
  gem 'sqlite3'
end

# Database drivers for running the specs against PostgreSQL or MySQL (via trilogy):
#   bundle config set --local with databases && bundle install
#   DATABASE_ADAPTER=postgresql bundle exec rspec
group :databases, optional: true do
  gem 'pg'
  gem 'trilogy'
end

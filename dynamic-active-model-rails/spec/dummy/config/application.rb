# frozen_string_literal: true

require 'logger'
require 'rails'
require 'active_record/railtie'
require 'dynamic-active-model-rails'

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    # reloading is on so specs can exercise the reloader
    config.enable_reloading = true
    config.logger = Logger.new(nil)
    config.secret_key_base = 'dummy'
  end
end

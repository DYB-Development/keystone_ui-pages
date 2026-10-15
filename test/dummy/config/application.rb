require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_job/railtie"
require "active_storage/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.action_controller.include_all_helpers = false

    config.paths["db/migrate"] << File.expand_path("../../../db/migrate", __dir__)
  end
end

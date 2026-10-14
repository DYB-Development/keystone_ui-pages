# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

ENV["DATABASE_URL"] = "sqlite3::memory:"

require "minitest/autorun"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require_relative "../lib/keystone_ui-pages"

class TestApp < Rails::Application
  config.root = File.expand_path("..", __dir__)
  config.eager_load = false
  config.secret_key_base = "keystone_ui_pages_test"
  config.logger = Logger.new(IO::NULL)
  config.active_support.deprecation = :silence
  config.active_record.maintain_test_schema = false
end

TestApp.initialize!

require "rails/test_help"

ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(KeystoneUi::Pages::Engine.root.join("db/migrate")).migrate

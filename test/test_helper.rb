# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../db/migrate", __dir__) ]
dummy_migrations = File.expand_path("../test/dummy/db/migrate", __dir__)
ActiveRecord::Migrator.migrations_paths << dummy_migrations if Dir.exist?(dummy_migrations)
require "rails/test_help"

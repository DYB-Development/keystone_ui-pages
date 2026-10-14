# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::MigrationsTest < Minitest::Test
  def test_the_migrations_give_a_pages_table_and_a_page_versions_table
    tables = ActiveRecord::Base.connection.tables

    assert_equal [ true, true ], [ tables.include?("keystone_ui_pages_pages"), tables.include?("keystone_ui_pages_versions") ]
  end
end

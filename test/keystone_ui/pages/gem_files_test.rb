# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::GemFilesTest < ActiveSupport::TestCase
  test "the gem ships the built editor script" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    assert_includes spec.files, "app/assets/builds/keystone_ui_pages/editor.js"
  end
end

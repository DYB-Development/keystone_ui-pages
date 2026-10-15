# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::GemFilesTest < ActiveSupport::TestCase
  test "the gem ships the built editor script" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    assert_includes spec.files, "app/assets/builds/keystone_ui_pages/editor.js"
  end

  test "the gem requires a keystone_ui with the heading, caption and paragraph components" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    refute spec.dependencies.find { |dependency| dependency.name == "keystone_ui" }.requirement.satisfied_by?(Gem::Version.new("0.41.0"))
  end

  test "the gem requires a keystone_ui with the value list component" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    refute spec.dependencies.find { |dependency| dependency.name == "keystone_ui" }.requirement.satisfied_by?(Gem::Version.new("0.43.0"))
  end
end

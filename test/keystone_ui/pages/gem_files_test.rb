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

  test "the gem requires a keystone_ui-styles that tells the browser a dark page is dark" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    assert_equal false, spec.dependencies.find { |dependency| dependency.name == "keystone_ui-styles" }&.requirement&.satisfied_by?(Gem::Version.new("0.20.0"))
  end

  test "the gem requires a keystone_ui whose table aligns columns, groups rows and ends with a total row" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    refute spec.dependencies.find { |dependency| dependency.name == "keystone_ui" }.requirement.satisfied_by?(Gem::Version.new("0.44.0"))
  end

  test "the gem requires a keystone_ui with the bar chart drawn on the server" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    refute spec.dependencies.find { |dependency| dependency.name == "keystone_ui" }.requirement.satisfied_by?(Gem::Version.new("0.45.0"))
  end

  test "the gem requires a keystone_ui-styles that prints dark pages light and keeps a light area light inside a dark page" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    refute spec.dependencies.find { |dependency| dependency.name == "keystone_ui-styles" }.requirement.satisfied_by?(Gem::Version.new("0.23.0"))
  end

  test "the gem requires a keystone_ui whose stat card takes a note, a plain style and a fallback" do
    spec = Gem::Specification.load(KeystoneUi::Pages::Engine.root.join("keystone_ui-pages.gemspec").to_s)

    refute spec.dependencies.find { |dependency| dependency.name == "keystone_ui" }.requirement.satisfied_by?(Gem::Version.new("0.48.0"))
  end
end

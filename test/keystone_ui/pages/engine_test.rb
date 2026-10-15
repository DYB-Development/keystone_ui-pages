# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::EngineTest < ActiveSupport::TestCase
  test "the package's views and drawing helpers are handed to the host's Tailwind build" do
    root = KeystoneUi::Pages::Engine.root

    assert_equal [ true, true ], [
      KeystoneUi.configuration.tailwind_sources.include?(root.join("app/views/**/*.erb").to_s),
      KeystoneUi.configuration.tailwind_sources.include?(root.join("app/helpers/**/*.rb").to_s)
    ]
  end

  test "the editor script's source is handed to the host's Tailwind build" do
    source = KeystoneUi::Pages::Engine.root.join("app/javascript/**/*.{js,jsx}").to_s

    assert_includes KeystoneUi.configuration.tailwind_sources, source
  end

  test "the element definitions are handed to the host's Tailwind build" do
    source = KeystoneUi::Pages::Engine.root.join("lib/keystone_ui/pages/**/*.rb").to_s

    assert_includes KeystoneUi.configuration.tailwind_sources, source
  end
end

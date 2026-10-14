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
end

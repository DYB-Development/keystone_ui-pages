# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PlaceElementsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a place registered with elements it leaves out offers every other element in the catalog" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :form ])

    assert_equal KeystoneUi::Pages.catalog.elements.map(&:key) - [ :form ], KeystoneUi::Pages.offered_elements("client_report").map(&:key)
  end
end

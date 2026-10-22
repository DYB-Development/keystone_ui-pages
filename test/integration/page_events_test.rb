# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageEventsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a place registered with an event handler is reported and one registered without it is not" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) {})
    KeystoneUi::Pages.register_place("client_report", label: "Client report")

    assert_equal [ true, false ], [ KeystoneUi::Pages.reported?("marketing"), KeystoneUi::Pages.reported?("client_report") ]
  end
end

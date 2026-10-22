# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageViewCountsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a place registered with counting on is counted and one registered without it is not" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    KeystoneUi::Pages.register_place("client_report", label: "Client report")

    assert_equal [ true, false ], [ KeystoneUi::Pages.counted?("marketing"), KeystoneUi::Pages.counted?("client_report") ]
  end
end

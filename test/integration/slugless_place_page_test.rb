# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::SluglessPlacePageTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a published page in a place registered with no URL slug is not served at the public page address" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", slug: false)
    KeystoneUi::Pages::Page.create!(name: "Monthly report", slug: "monthly-report", place: "client_report").publish

    get "/pages/monthly-report"

    assert_response :not_found
  end

  test "a published page in a place with a URL slug is still served at the public page address" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish

    get "/pages/pricing"

    assert_response :ok
  end
end

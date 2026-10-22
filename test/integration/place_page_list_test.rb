# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PlacePageListTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_report" => "Client report" }
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
    KeystoneUi::Pages::Page.create!(name: "Invoice report", slug: "invoice-report", place: "client_report")
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a page list opened with a place shows only the pages in that place" do
    get "/pages/manage/pages", params: { place: "marketing" }

    assert_equal [ "pricing" ], Nokogiri::HTML(response.body).css("tr[data-page]").map { |row| row["data-page"] }
  end
end

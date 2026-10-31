# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::UnlistedPlaceTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "the page list with no place chosen leaves out the pages of an unlisted place" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false)
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel")

    get "/pages/manage/pages"

    assert_equal [ "Pricing" ], Nokogiri::HTML(response.body).css("[data-page]").map { |row| row.css("td").first.text.strip }
  end
end

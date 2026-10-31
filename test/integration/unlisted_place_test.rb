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

  test "the archived page list leaves out the pages of an unlisted place" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false)
    KeystoneUi::Pages::Page.create!(name: "Old pricing", slug: "old-pricing", place: "marketing").archive
    KeystoneUi::Pages::Page.create!(name: "Old landing", slug: "old-landing", place: "funnel").archive

    get "/pages/manage/pages", params: { archived: 1 }

    assert_equal [ "Old pricing" ], Nokogiri::HTML(response.body).css("[data-page]").map { |row| row.css("td").first.text.strip }
  end

  test "the Create page form's place menu does not offer an unlisted place" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false)

    get "/pages/manage/pages/new"

    assert_equal [ "Marketing site" ], Nokogiri::HTML(response.body).css("select[name='page[place]'] option").map { |option| option.text.strip }.reject(&:empty?)
  end
end

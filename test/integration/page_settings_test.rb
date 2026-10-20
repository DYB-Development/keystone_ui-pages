# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageSettingsTest < ActionDispatch::IntegrationTest
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
  end

  test "the page list links each page to its settings" do
    get "/pages/manage/pages"

    assert_equal "/pages/manage/pages/#{@page.id}/edit", Nokogiri::HTML(response.body).at_css("[data-page='pricing'] a:contains('Settings')")&.[]("href")
  end

  test "the settings page shows the page's name and slug in editable fields" do
    get "/pages/manage/pages/#{@page.id}/edit"

    fields = Nokogiri::HTML(response.body).css("input[name='page[name]'], input[name='page[slug]']").map { |field| field["value"] }
    assert_equal [ "Pricing", "pricing" ], fields
  end

  test "the settings page shows the page's place as the chosen place" do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_portal" => "Client portal" }
    @page.update!(place: "client_portal")

    get "/pages/manage/pages/#{@page.id}/edit"

    assert_equal "client_portal", Nokogiri::HTML(response.body).at_css("select[name='page[place]'] option[selected]")&.[]("value")
  ensure
    KeystoneUi::Pages.places = nil
  end

  test "saving the settings changes the page's slug" do
    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "plans" } }

    assert_equal "plans", @page.reload.slug
  end
end

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
end

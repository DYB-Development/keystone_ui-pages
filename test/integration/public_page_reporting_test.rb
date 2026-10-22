# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_document"

class KeystoneUi::Pages::PublicPageReportingTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a page from a place with no handler at its public address loads no reporting script and gives no event address" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    KeystoneUi::Pages.register_place("help", label: "Help centre")
    KeystoneUi::Pages::Page.create!(name: "Returns", slug: "returns", place: "help").publish

    get "/pages/returns"

    assert_select "script[src*='keystone_ui_pages/reporting'], [data-page-events]", 0
  end

  test "opening a page through the editor's View live loads no reporting script and gives no event address" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").tap(&:publish)

    get "/pages/manage/pages/#{page.id}/live"

    assert_select "script[src*='keystone_ui_pages/reporting'], [data-page-events]", 0
  end

  test "a page printed as a PDF holds no reporting script and no event address" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").tap(&:publish)

    html = KeystoneUi::Pages::PdfDocument.html(page.live_version, values: {})

    assert_empty Nokogiri::HTML(html).css("script[src*='keystone_ui_pages/reporting'], [data-page-events]")
  end
end

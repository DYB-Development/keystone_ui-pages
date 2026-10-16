# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"

class KeystoneUi::Pages::PageListTest < ActionDispatch::IntegrationTest
  test "the page list shows each page's name, whether it is published and when it was last published" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").publish
    KeystoneUi::Pages::Page.create!(name: "Draft", slug: "draft")

    get "/pages/manage/pages"

    rows = Nokogiri::HTML(response.body).css("[data-page]").map { |row| row.css("td").first(3).map { |cell| cell.text.strip } }
    assert_equal [ [ "Draft", "Draft", "" ], [ "Pricing", "Published", Date.current.to_fs(:long) ] ], rows
  end

  test "an editor opens a page in the builder from the page list" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages"

    assert_equal "/pages/manage/pages/#{page.id}", Nokogiri::HTML(response.body).at_css("[data-page='pricing'] a:contains('Edit')")&.[]("href")
  end

  test "an editor opens a published page's live version from the page list" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish

    get "/pages/manage/pages"

    assert_equal "/pages/manage/pages/#{page.id}/live", Nokogiri::HTML(response.body).at_css("[data-page='pricing'] a:contains('View live')")&.[]("href")
  end

  test "an editor downloads a published page's PDF from the page list" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").publish
    get "/pages/manage/pages"
    link = Nokogiri::HTML(response.body).at_css("[data-page='pricing'] a:contains('PDF')")&.[]("href")

    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { "%PDF-printed" }) { get link.to_s }

    assert_equal [ "application/pdf", "%PDF-printed" ], [ response.media_type, response.body ]
  end
end

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

  test "the page list has no place or access exception columns when the host names neither" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages"

    assert_equal [ "Name", "Status", "Last published", "Open" ], Nokogiri::HTML(response.body).css("th").map { |cell| cell.text.strip }
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
    KeystoneUi::Pages::Printer.stub(:chrome, "/usr/bin/chromium") { get "/pages/manage/pages" }
    link = Nokogiri::HTML(response.body).at_css("[data-page='pricing'] a:contains('PDF')")&.[]("href")

    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { "%PDF-printed" }) { get link.to_s }

    assert_equal [ "application/pdf", "%PDF-printed" ], [ response.media_type, response.body ]
  end

  test "the page list offers no PDF when no Chrome is found to print one" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").publish

    KeystoneUi::Pages::Printer.stub(:chrome, nil) { get "/pages/manage/pages" }

    assert_equal [ true, false ], [ response.body.include?("View live"), Nokogiri::HTML(response.body).css("[data-page='pricing'] a").map(&:text).include?("PDF") ]
  end
end

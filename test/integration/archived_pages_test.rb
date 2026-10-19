# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::ArchivedPagesTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    KeystoneUi::Pages::Page.create!(name: "Old offer", slug: "old-offer").archive
  end

  test "the page list leaves out archived pages" do
    get "/pages/manage/pages"

    assert_equal [ "pricing" ], Nokogiri::HTML(response.body).css("[data-page]").map { |row| row["data-page"] }
  end

  test "an editor shows archived pages in the page list" do
    get "/pages/manage/pages"
    link = Nokogiri::HTML(response.body).at_css("a:contains('Show archived')")&.[]("href")

    get link.to_s

    assert_equal [ "old-offer" ], Nokogiri::HTML(response.body).css("[data-page]").map { |row| row["data-page"] }
  end

  test "an editor restores an archived page from the archived pages list" do
    get "/pages/manage/pages", params: { archived: 1 }
    action = Nokogiri::HTML(response.body).at_css("[data-page='old-offer'] form:has(button:contains('Restore'))")&.[]("action")

    post action.to_s
    get "/pages/manage/pages"

    assert_equal [ "old-offer", "pricing" ], Nokogiri::HTML(response.body).css("[data-page]").map { |row| row["data-page"] }
  end

  test "an editor archives a page from the page list" do
    get "/pages/manage/pages"
    action = Nokogiri::HTML(response.body).at_css("[data-page='pricing'] form:has(button:contains('Archive'))")&.[]("action")

    post action.to_s

    assert_equal :archived, KeystoneUi::Pages::Page.find_by(slug: "pricing").state
  end

  test "the page list shows an unpublished page as unpublished" do
    unpublished = KeystoneUi::Pages::Page.create!(name: "Launch", slug: "launch")
    unpublished.publish
    unpublished.unpublish

    get "/pages/manage/pages"

    assert_equal "Unpublished", Nokogiri::HTML(response.body).css("[data-page='launch'] td")[1].text.strip
  end
end

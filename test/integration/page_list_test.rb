# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageListTest < ActionDispatch::IntegrationTest
  test "the page list shows each page's name, whether it is published and when it was last published" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").publish
    KeystoneUi::Pages::Page.create!(name: "Draft", slug: "draft")

    get "/pages/manage/pages"

    rows = Nokogiri::HTML(response.body).css("[data-page]").map { |row| row.css("td").first(3).map { |cell| cell.text.strip } }
    assert_equal [ [ "Draft", "Draft", "" ], [ "Pricing", "Published", Date.current.to_fs(:long) ] ], rows
  end
end

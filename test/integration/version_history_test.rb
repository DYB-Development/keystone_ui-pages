# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::VersionHistoryTest < ActionDispatch::IntegrationTest
  test "the builder's history lists a page's published versions with each number, status and date" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish
    page.publish

    get "/pages/manage/pages/#{page.id}/versions"

    rows = Nokogiri::HTML(response.body).css("[data-version]").map { |row| row.css("td").map { |cell| cell.text.strip } }
    assert_equal [ [ "2", "live", Date.current.to_fs(:long) ], [ "1", "superseded", Date.current.to_fs(:long) ] ], rows.map { |cells| cells.first(3) }
  end
end

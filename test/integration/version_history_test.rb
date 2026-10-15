# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::VersionHistoryTest < ActionDispatch::IntegrationTest
  test "the builder's history lists a page's published versions with each number, status and date" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish
    page.publish

    get "/pages/manage/pages/#{page.id}/versions"

    rows = Nokogiri::HTML(response.body).css("[data-version]").map { |row| row.css("td").map { |cell| cell.text.strip } }
    assert_equal [ [ "2", "live", Date.current.to_fs(:long) ], [ "1", "superseded", Date.current.to_fs(:long) ] ], rows.map { |cells| cells.first(3) }
  end

  test "an editor opens an earlier version and sees it drawn as it was published" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    element_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: element_id, field: "label", value: "First"))
    page.publish
    page.update!(document: KeystoneUi::Pages::Operations.set(page.document, element_id: element_id, field: "label", value: "Second"))
    page.publish

    get "/pages/manage/pages/#{page.id}/versions/#{page.versions.find_by(number: 1).id}"

    assert_equal "First", Nokogiri::HTML(response.body).at_css(".ks-pages-element .ks-button").text.strip
  end
end

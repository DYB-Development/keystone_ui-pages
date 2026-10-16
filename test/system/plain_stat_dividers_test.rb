# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PlainStatDividersTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "plain stats side by side in a row are separated by thin dividers on the live page" do
    page_record = published_row_of_plain_stats


    visit "/pages/report"

    assert_equal %w[0px 1px 1px], page.evaluate_script("[...document.querySelectorAll('.ks-pages-column')].map((column) => getComputedStyle(column).borderLeftWidth)")
  end

  test "a row of plain stats with notes and a missing value is drawn in the builder exactly as on the live page" do
    page_record = published_row_of_plain_stats
    visit "/pages/manage/pages/#{page_record.id}"
    assert_selector "[data-element-id] .ks-stat-card-fallback"
    built = drawn_row

    visit "/pages/report"

    assert_equal built, drawn_row
  end

  private

  def published_row_of_plain_stats
    page_record = KeystoneUi::Pages::Page.create!(name: "Report", slug: "report")
    document = page_record.document
    row_id = document["sections"][0]["rows"][0]["id"]
    2.times { document = KeystoneUi::Pages::Operations.add_column(document, row_id: row_id) }
    document["sections"][0]["rows"][0]["columns"].each do |column|
      document = KeystoneUi::Pages::Operations.add(document, "stat_card", column_id: column["id"])
      element_id = KeystoneUi::Pages::Operations.column(document, column["id"])["elements"][0]["id"]
      document = KeystoneUi::Pages::Operations.set(document, element_id: element_id, field: "plain", value: "true")
      document = KeystoneUi::Pages::Operations.set(document, element_id: element_id, field: "note", value: "Across 6 days")
    end
    document["sections"][0]["rows"][0]["columns"][2]["elements"][0]["fields"]["value"] = { "value" => "reviews", "fallback" => nil }
    page_record.update!(document: document)
    page_record.publish
    page_record
  end

  def drawn_row
    page.evaluate_script(<<~JS)
      [...document.querySelectorAll(".ks-pages-column")].map((column) => [
        column.querySelector(".ks-pages-element").innerHTML,
        getComputedStyle(column).borderLeftWidth
      ])
    JS
  end
end

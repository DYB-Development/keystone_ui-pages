# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::SelectionPathTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page_record.update!(document: KeystoneUi::Pages::Operations.add(@page_record.document, "button", column_id: column_id))
    visit "/pages/manage/pages/#{@page_record.id}"
  end

  test "the builder shows the path from the section down to the selected element" do
    find("[data-element-id] .ks-button").click

    assert_equal %w[Section Row Column Button], all("[data-selection-path] button").map(&:text)
  end

  test "with an element selected, choosing Column in the path selects the column that holds it" do
    find("[data-element-id] .ks-button").click

    within("[data-selection-path]") { click_on "Column" }

    assert_selector "[data-column-id][data-selected]"
  end
end

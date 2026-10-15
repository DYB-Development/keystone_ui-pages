# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PlaceholderLivePageTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "the live page shows the same placeholder content the builder showed for a field the editor left unchanged" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id))
    visit "/pages/manage/pages/#{page_record.id}"
    built = find("[data-element-id] .ks-button").text
    page_record.publish

    visit "/pages/pricing"

    assert_equal [ "Button", built ], [ built, find(".ks-pages-element .ks-button").text ]
  end
end

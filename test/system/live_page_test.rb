# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::LivePageTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "a page's address shows its live version drawn with keystone_ui components inside the host's layout" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id)
    element_id = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.set(added, element_id: element_id, field: "label", value: "Get a quote"))
    page_record.publish

    visit "/pages/pricing"

    assert_selector "[data-host-layout] .ks-button", text: "Get a quote"
  end
end

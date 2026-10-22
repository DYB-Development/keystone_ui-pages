# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::BuilderFormTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "an editor adds a form from the builder's element list beside another element" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id))
    visit "/pages/manage/pages/#{page_record.id}"

    dragged(find("[data-element-palette] [data-element-key='form']"), find("[data-column-id]"))

    assert_selector "[data-column-id]:has([data-element-id] .ks-button):has([data-element-id] .ks-form)"
  end
end

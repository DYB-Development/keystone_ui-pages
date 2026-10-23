# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormTrapBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(_submission) { })
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "form", column_id: column_id))
    page_record.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a form's trap field is drawn where people cannot see it" do
    visit "/pages/contact"

    assert_equal true, page.evaluate_script("document.querySelector('[name=keystone_ui_pages_trap]').getBoundingClientRect().right < 0")
  end
end

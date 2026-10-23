# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormsOffPaperBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(_submission) { })
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "form", column_id: column_id))
    page_record.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
  end

  test "a visitor printing a page from the browser sees no form on paper" do
    visit "/pages/contact"
    printed

    assert_equal false, page.evaluate_script("document.querySelector('form.ks-form').checkVisibility()")
  end

  private

  def printed
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
  end
end

# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormChecksBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(_submission) { })
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "form", column_id: column_id))
    page_record.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.layout = nil
  end

  test "on a page running Turbo, a refused visitor sees the errors in place of the form with the rest of the page unchanged, at the engine's address and in the host's view" do
    KeystoneUi::Pages.layout = "turbo"

    shown = [ "/pages/contact", "/products/contact?layout=turbo" ].map do |path|
      visit path
      page.execute_script("document.body.dataset.stayedOnPage = 'true'")
      fill_in "name", with: "Ada"
      fill_in "email", with: ""
      click_on "Send"
      [ page.has_css?(".ks-error", text: "Fill this in"), page.evaluate_script("document.body.dataset.stayedOnPage === 'true'"), find_field("name").value ]
    end

    assert_equal [ [ true, true, "Ada" ] ] * 2, shown
  end
end

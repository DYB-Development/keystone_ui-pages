# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FailedReportBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a reporting script whose request fails leaves the page working and shows the visitor nothing" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id)
    button_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: button_id, field: "label", value: "Get a quote"))
    page_record.publish

    with_event_address_blocked do
      visit "/pages/pricing"
      click_on "Get a quote"

      assert_equal [ [], true ], [ wait_for { page.evaluate_script("window.pageErrors").presence }.to_a, page.has_button?("Get a quote") ]
    end
  end
end

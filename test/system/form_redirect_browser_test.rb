# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormRedirectBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission.values })
    next_steps = KeystoneUi::Pages::Page.create!(name: "Next steps", slug: "next-steps", place: "marketing")
    next_steps.update!(document: next_steps.document.merge("title" => "Next steps"))
    next_steps.publish
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page_record.document, "form", column_id: column_id)
    form_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    document = KeystoneUi::Pages::Operations.set(document, element_id: form_id, field: "after_submitting", value: "address")
    page_record.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: form_id, field: "next_address", value: "/pages/next-steps"))
    page_record.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "on a page running Turbo, a visitor who submits a form set to send them to an address leaves the page for that address once the handler has the submission" do
    visit "/products/contact?layout=turbo"
    page.execute_script("document.body.dataset.stayedOnPage = 'true'")

    fill_in "name", with: "Ada"
    fill_in "email", with: "ada@example.com"
    click_on "Send"

    assert_equal [ true, nil, 1 ], [ page.has_current_path?("/pages/next-steps"), page.evaluate_script("document.body.dataset.stayedOnPage"), @received.size ]
  end
end

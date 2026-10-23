# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormSubmissionBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission.values })
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "form", column_id: column_id))
    page_record.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "on a page running Turbo, the thank-you message replaces the form and the rest of the page stays as it was" do
    visit "/products/contact?layout=turbo"
    page.execute_script("document.body.dataset.stayedOnPage = 'true'")

    fill_in "name", with: "Ada"
    fill_in "email", with: "ada@example.com"
    click_on "Send"

    assert_equal [ true, true, false ],
      [ page.has_text?("Thanks, we will be in touch."), page.evaluate_script("document.body.dataset.stayedOnPage === 'true'"), page.has_css?("form.ks-form", wait: 0) ]
  end

  test "a form submitted from a page at the engine's address and from a page drawn in the host's own view both reach the handler" do
    [ [ "/pages/contact", "Ada" ], [ "/products/contact", "Bo" ] ].each do |path, name|
      visit path
      fill_in "name", with: name
      fill_in "email", with: "#{name.downcase}@example.com"
      click_on "Send"
      page.has_current_path?(%r{/forms/}) && page.has_text?("Thanks, we will be in touch.")
    end

    assert_equal %w[Ada Bo], @received.map { |values| values["name"] }
  end
end

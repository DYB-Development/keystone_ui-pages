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

  test "an editor sets a form's name, submit label and thank-you message" do
    page_record = selected_form

    fill_in "ks-pages-field-form_name", with: "Quote request"
    fill_in "ks-pages-field-submit_label", with: "Ask for a quote"
    fill_in "ks-pages-field-thank_you", with: "We will reply within a day."
    find("[data-element-fields] label", text: "Form name").click

    assert_equal [ "Quote request", "Ask for a quote", "We will reply within a day." ],
      wait_for { form_fields(page_record).values_at("form_name", "submit_label", "thank_you").then { |saved| saved if saved.none?(&:nil?) } }
  end

  private

  def selected_form
    page_record = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "form", column_id: column_id))
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-element-id] .ks-form button").click
    page_record
  end

  def form_fields(page_record)
    page_record.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
  end
end

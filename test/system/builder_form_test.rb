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

  test "an editor adds, removes and reorders a form's fields, giving each a label, a field name, a kind and whether it is required" do
    page_record = selected_form

    within("[data-list-field='fields']") { click_on "Add item" }
    fill_in "ks-pages-fields-2-label", with: "Message"
    find("[data-element-fields] label", text: "Form name").click
    fill_in "ks-pages-fields-2-name", with: "message"
    find("[data-element-fields] label", text: "Form name").click
    select "long_text", from: "ks-pages-fields-2-kind"
    check "ks-pages-fields-2-required"
    within(all("[data-list-entry]").first) { click_on "Remove item" }
    within(all("[data-list-entry]").last) { click_on "Move up" }

    expected = [ { "label" => "Message", "name" => "message", "kind" => "long_text", "required" => "true" },
                 { "label" => "Email", "name" => "email", "kind" => "email", "required" => "true" } ]
    assert_equal expected, wait_for { form_fields(page_record)["fields"].then { |saved| saved if saved == expected } } || form_fields(page_record)["fields"]
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

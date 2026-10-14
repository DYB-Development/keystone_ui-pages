# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::BuilderFieldsTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "a long text field is edited in a text area" do
    selected("alert", ".ks-alert")

    assert_selector "[data-element-fields] textarea#ks-pages-field-message"
  end

  test "a number field is edited in a number input" do
    selected("progress", ".ks-progress-track")

    assert_selector "[data-element-fields] input[type='number']#ks-pages-field-value"
  end

  test "an address field is edited in a web address input" do
    selected("card", ".ks-card")

    assert_selector "[data-element-fields] input[type='url']#ks-pages-field-link"
  end

  test "a one of a list field is chosen from its options" do
    selected("alert", ".ks-alert")

    assert_equal %w[info success warning error], all("select#ks-pages-field-type option").map(&:value)
  end

  private

  def selected(key, drawn)
    page_record = KeystoneUi::Pages::Page.create!(name: "Fields", slug: "fields")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, key, column_id: column_id))
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-element-id] #{drawn}").click
  end
end

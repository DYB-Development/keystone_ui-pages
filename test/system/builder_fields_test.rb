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

  test "a yes or no field is a checkbox that redraws the element when ticked" do
    selected("alert", ".ks-alert")

    check "Can be dismissed"

    assert_selector "[data-element-id] .ks-alert-dismiss"
  end

  test "a field the editor has not changed shows its default in the settings panel" do
    selected("hero", "h1")

    assert_equal [ "Headline", "split" ], [ find_field("Title").value, find_field("Layout").value ]
  end

  test "the settings panel shows a new alert's placeholder message as the field's current value" do
    selected("alert", ".ks-alert")

    assert_equal "Something worth knowing.", find_field("Message").value
  end

  test "changing a field in the settings panel replaces its placeholder content" do
    selected("button", ".ks-button")

    fill_in "Label", with: "Get a quote"
    find("[data-element-fields] label", text: "Address").click

    assert_selector "[data-element-id] .ks-button", text: "Get a quote"
  end

  test "the settings panel shows start as a newly dropped button's alignment" do
    selected("button", ".ks-button")

    assert_equal "start", find_field("Horizontal alignment").value
  end

  test "an editor changes a button from its starting alignment to stretch" do
    selected("button", ".ks-button")

    select "stretch", from: "Horizontal alignment"

    assert_selector "[data-element-id].flex-col"
  end

  test "an editor binds a field to one of the host's named values instead of typed text" do
    KeystoneUi::Pages::Values.names = { "client_name" => "Client name" }
    selected("button", ".ks-button")

    find("#ks-pages-value-label").select("Client name")

    assert_selector "[data-element-fields]", text: "Shows Client name, or this text when it has no value"
    assert_equal({ "value" => "client_name", "fallback" => "Button" }, KeystoneUi::Pages::Page.last.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"])
  ensure
    KeystoneUi::Pages::Values.names = {}
  end

  test "an editor adds an entry to a list field from the builder" do
    selected("accordion", ".ks-accordion")

    within("[data-list-field='items']") { click_on "Add item" }

    assert_selector "[data-element-id] .ks-accordion-item", count: 3
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

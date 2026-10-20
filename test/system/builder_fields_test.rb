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

  test "an editor sets a feature's icon in a feature grid from the builder" do
    selected("feature_grid", "h2")

    fill_in "ks-pages-features-0-icon", with: "✨"
    find("[data-element-fields] label", text: "Horizontal alignment").click

    assert_selector "[data-element-id] .ks-feature-card-icon", text: "✨"
  end

  test "an editor edits an entry of a list field from the builder" do
    selected("accordion", ".ks-accordion")

    fill_in "ks-pages-items-0-question", with: "Is it free?"
    find("[data-element-fields] label", text: "Horizontal alignment").click

    assert_selector "[data-element-id] .ks-accordion-item", text: "Is it free?"
  end

  test "an editor removes an entry from a list field from the builder" do
    selected("accordion", ".ks-accordion")

    within(all("[data-list-entry]").first) { click_on "Remove item" }

    assert_selector "[data-element-id] .ks-accordion-item", count: 1, text: "How does it work?"
  end

  test "an editor reorders the entries of a list field from the builder" do
    selected("accordion", ".ks-accordion")

    within(all("[data-list-entry]").last) { click_on "Move up" }

    assert_selector "[data-element-id] .ks-accordion-item:first-child", text: "How does it work?"
  end

  test "an editor marks a value list row as the total by ticking its total box" do
    selected("value_list", ".ks-value-list")

    find("#ks-pages-rows-2-total").click

    assert_selector "[data-element-id] .ks-value-list-total .ks-value-list-label", text: "Issued"
  end

  test "a value list row's fallback box shows the fallback in use when the editor has not changed it" do
    selected("value_list", ".ks-value-list")

    assert_equal "N/A", find("#ks-pages-rows-0-fallback").value
  end

  test "a value list row's total box sits at the left under its label instead of stretching across the panel" do
    selected("value_list", ".ks-value-list")

    width = evaluate_script("document.querySelector('#ks-pages-rows-0-total').getBoundingClientRect().width")

    assert_operator width, :<, 40
  end

  test "an editor aligns a table column to the end from a choice in the builder" do
    selected("data_table", "tbody tr:first-child td:first-child")

    find("#ks-pages-columns-0-align").select("end")

    assert_selector "[data-element-id] thead th:first-child.text-right"
  end

  test "the builder draws a list bound to a value its preview does not supply with no rows" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(page_record.document, "value_list", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = { "value" => "billing", "fallback" => nil }
    page_record.update!(document: added)

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-element-id] .ks-value-list", visible: :all
  end

  test "an editor sets an element to show only when a host value equals a chosen value" do
    KeystoneUi::Pages::Values.names = { "audience" => "Audience" }
    selected("button", ".ks-button")

    find("#ks-pages-show-when-value").select("Audience")
    fill_in "ks-pages-show-when-equals", with: "internal"
    find("[data-element-fields] label", text: "Horizontal alignment").click

    assert_selector "[data-element-id][data-hidden] .ks-button"
  ensure
    KeystoneUi::Pages::Values.names = {}
  end

  test "the builder fades an element its sample hides so an editor can see it is hidden" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }
    page_record.update!(document: added)

    visit "/pages/manage/pages/#{page_record.id}"

    assert_operator page.evaluate_script("Number(getComputedStyle(document.querySelector('[data-element-id][data-hidden]')).opacity)"), :<, 1
  end

  test "an editor selects and edits an element its sample hides" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }
    page_record.update!(document: added)
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-element-id][data-hidden] .ks-button").click
    fill_in "Label", with: "Cost of goods"
    find("[data-element-fields] label", text: "Address").click

    assert_selector "[data-element-id][data-hidden] .ks-button", text: "Cost of goods"
  end

  test "a data field says the host fills it instead of offering a text box" do
    selected("data_table", "tbody tr:first-child td:first-child")

    assert_equal [ false, true ], [ has_field?("Rows"), has_css?("[data-element-fields]", text: "Filled with data the host supplies on a template page") ]
  end

  test "an editor adds a link to the selected words of a paragraph" do
    selected("paragraph", ".ks-paragraph")
    text = find("[data-rich-text-field] [contenteditable]")
    text.click
    text.send_keys([ :command, "a" ], [ :control, "a" ], "Tyler")
    text.send_keys([ :command, "a" ], [ :control, "a" ])

    within("[data-rich-text-field]") do
      click_on "Link"
      fill_in "Link address", with: "https://ty-ler.com"
      click_on "Save link"
    end
    find("[data-element-fields] label", text: "Horizontal alignment").click

    assert_selector "[data-element-id] .ks-paragraph a[href='https://ty-ler.com']", text: "Tyler"
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

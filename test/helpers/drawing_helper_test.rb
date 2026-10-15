# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::DrawingHelperTest < ActionView::TestCase
  helper KeystoneUiHelper
  include KeystoneUi::Pages::DrawingHelper

  setup do
    @document = KeystoneUi::Pages::Document.blank
  end

  test "a section is drawn with keystone_ui's class for its spacing" do
    @document["sections"][0]["spacing"] = "lg"

    render html: drawn_document(@document)

    assert_select "section.ks-pages-section.ks-section-lg"
  end

  test "a row is drawn as a twelve-column grid with keystone_ui's class for its gap" do
    @document["sections"][0]["rows"][0]["gap"] = "xl"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-row.grid.grid-cols-12.ks-grid-gap-xl"
  end

  test "a column is drawn with its widths for narrow and wide screens" do
    column = @document["sections"][0]["rows"][0]["columns"][0]
    column["narrow"] = "1/2"
    column["wide"] = "1/3"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-column.col-span-6.\\@sm\\:col-span-4"
  end

  test "a column is drawn with its vertical alignment" do
    @document["sections"][0]["rows"][0]["columns"][0]["align"] = "bottom"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-column.justify-end"
  end

  test "an element is drawn inside a wrapper carrying its horizontal alignment" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["align"] = "center"

    render html: drawn_document(added)

    assert_select "div.ks-pages-element.flex.justify-center > .ks-button"
  end

  test "a number field reaches its component as a number" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "progress", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "value" => "40", "max" => "80" }

    render html: drawn_document(added)

    assert_select ".ks-progress-bar[style*='50%']"
  end

  test "a one of a list field reaches its component as the chosen option" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "message" => "Saved", "type" => "success" }

    render html: drawn_document(added)

    assert_select ".ks-alert.ks-alert-success"
  end

  test "a yes or no field reaches its component as true or false" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "message" => "Saved", "type" => "info", "dismissible" => "false" }

    render html: drawn_document(added)

    assert_select ".ks-alert-dismiss", 0
  end

  test "a field with no value reaches its component as the field's default" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "message" => "Saved" }

    render html: drawn_document(added)

    assert_select ".ks-alert.ks-alert-info"
  end

  test "an element whose component takes nested content draws its body field as that content" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "code", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "code" => "puts 1", "language" => "ruby" }

    render html: drawn_document(added)

    assert_select ".ks-pages-element", text: /puts 1/
  end

  test "a newly dropped button shows a label" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]

    render html: drawn_document(KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id))

    assert_select ".ks-button", text: "Button"
  end

  test "a newly dropped alert shows a message" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]

    render html: drawn_document(KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id))

    assert_select ".ks-alert-message", text: "Something worth knowing."
  end

  test "every element in the default catalog shows visible content as soon as it is dropped" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    defaults = KeystoneUi::Pages::Catalog.new.tap { |catalog| KeystoneUi::Pages::KeystoneElements.register(catalog) }.elements.map(&:key)
    keys = defaults & KeystoneUi::Pages.catalog.elements.map(&:key)

    blank = keys.select do |key|
      html = drawn_document(KeystoneUi::Pages::Operations.add(@document, key, column_id: column_id))
      Nokogiri::HTML(html).at_css(".ks-pages-element").text.strip.empty?
    end

    assert_equal [], blank
  end

  test "a newly dropped button keeps its natural width at the start of its column" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]

    render html: drawn_document(KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id))

    assert_select "div.ks-pages-element.flex.justify-start > .ks-button"
  end

  test "a newly dropped card, alert, hero or code block still fills its column" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = %w[card alert hero code].reduce(@document) { |filled, key| KeystoneUi::Pages::Operations.add(filled, key, column_id: column_id) }

    render html: drawn_document(document)

    assert_select "div.ks-pages-element.flex.flex-col", count: 4
  end

  test "a bound field shows the value the host hands in under its name" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => "Our client" }

    render html: drawn_document(added, values: { "client_name" => "Acme" })

    assert_select ".ks-button", text: "Acme"
  end

  test "a bound field whose value is missing draws its fallback" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => "Our client" }

    render html: drawn_document(added, values: {})

    assert_select ".ks-button", text: "Our client"
  end

  test "a bound field whose value is missing and that has no fallback draws nothing" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }

    render html: drawn_document(added, values: {})

    assert_select ".ks-button", text: ""
  end

  test "a list field bound to a host value draws the rows the host supplies" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "feature_grid", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["features"] = { "value" => "highlights", "fallback" => nil }

    render html: drawn_document(added, values: { "highlights" => [ { "title" => "Uptime" }, { "title" => "Support" } ] })

    assert_equal %w[Uptime Support], css_select("h3").map { |heading| heading.text.strip }
  end
end

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
      drawn = Nokogiri::HTML(html).at_css(".ks-pages-element")
      drawn.text.strip.empty? && drawn.at_css("canvas").nil?
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

  test "a heading's note bound to a host value shows that value" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "heading", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["note"] = { "value" => "hours", "fallback" => nil }

    render html: drawn_document(added, values: { "hours" => "12.5 billable hours" })

    assert_select ".ks-heading-row .ks-heading-note", text: "12.5 billable hours"
  end

  test "a typed value list row whose total switch is off is not drawn as a total" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "value_list", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = [ { "label" => "Rate", "value" => "$150.00", "total" => "false" } ]

    render html: drawn_document(added)

    assert_select ".ks-value-list-total", count: 0
  end

  test "a typed value list row whose total switch is on is drawn as a total" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "value_list", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = [ { "label" => "Total billed", "value" => "$1,875.00", "total" => "true" } ]

    render html: drawn_document(added)

    assert_select ".ks-value-list-total .ks-value-list-label", text: "Total billed"
  end

  test "a typed value list row with no value draws its fallback" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "value_list", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = [ { "label" => "Reviews", "value" => "" } ]

    render html: drawn_document(added)

    assert_select ".ks-value-list-value", text: "N/A"
  end

  test "value list rows the host supplies draw their fallback where a value is missing" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "value_list", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = { "value" => "billing", "fallback" => nil }

    render html: drawn_document(added, values: { "billing" => [ { "label" => "Rate", "value" => "$150.00" }, { "label" => "Reviews", "value" => nil } ] })

    assert_equal [ "$150.00", "N/A" ], css_select(".ks-value-list-value").map { |value| value.text.strip }
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

  test "a data table draws the rows the host supplies under the columns the editor listed" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["items"] = { "value" => "orders", "fallback" => nil }
    fields["columns"] = [ { "key" => "number", "label" => "Order" } ]

    render html: drawn_document(added, values: { "orders" => [ { "number" => "A-1" }, { "number" => "A-2" } ] })

    assert_equal [ "Order", %w[A-1 A-2] ], [ css_select("th").map { |cell| cell.text.strip }.first, css_select("td").map { |cell| cell.text.strip } ]
  end

  test "a line chart draws the series and labels the host supplies" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "line_chart", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["series"] = { "value" => "scores", "fallback" => nil }
    fields["labels"] = { "value" => "weeks", "fallback" => nil }

    render html: drawn_document(added, values: { "scores" => [ { "name" => "Score", "data" => [ 60, 72 ] } ], "weeks" => %w[W1 W2] })

    chart = JSON.parse(css_select("[data-line-chart-data-value]").first["data-line-chart-data-value"])
    assert_equal [ %w[W1 W2], "Score", [ 60, 72 ] ], [ chart["labels"], chart["datasets"][0]["label"], chart["datasets"][0]["data"] ]
  end

  test "a hero set to content height drops keystone_ui's full-screen minimum height" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "hero", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["height"] = "content"

    render html: drawn_document(added)

    assert_select ".ks-pages-element[class~='[&_.ks-hero]:min-h-0'] .ks-hero"
  end
end

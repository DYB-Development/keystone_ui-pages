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

  test "a shaded section is drawn with keystone_ui's muted fill colour in light and dark themes" do
    @document["sections"][0]["background"] = "shaded"

    render html: drawn_document(@document)

    assert_select "section.ks-pages-section.bg-\\(color\\:--ks-color-fill-muted\\).dark\\:bg-\\(color\\:--ks-color-fill-muted-dark\\)"
  end

  test "a section with a width set holds its rows at keystone_ui's page width of that name with its page side padding" do
    @document["sections"][0]["width"] = "lg"

    render html: drawn_document(@document)

    assert_select "section.ks-pages-section > div.ks-page.ks-page-lg > div.ks-pages-row"
  end

  test "a section with a width set is padded above and below by an amount built from keystone_ui's spacing value" do
    @document["sections"][0]["width"] = "lg"

    render html: drawn_document(@document)

    assert_select "div.ks-page.py-\\[calc\\(var\\(--ks-spacing\\)\\*16\\)\\].lg\\:py-\\[calc\\(var\\(--ks-spacing\\)\\*24\\)\\]"
  end

  test "a section saved without a background or width draws as it did before either existed" do
    render html: drawn_document(@document)

    section = css_select("section.ks-pages-section").first
    assert_equal [ "ks-pages-section flex flex-col gap-6 print:break-inside-avoid ks-section-md", "ks-pages-row" ], [ section["class"], section.element_children.first["class"].split.first ]
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

  test "a stat's note bound to a host value shows that value under the stat" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "stat_card", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["note"] = { "value" => "hours_note", "fallback" => nil }

    render html: drawn_document(added, values: { "hours_note" => "Across 6 days" })

    assert_select ".ks-stat-card-note", text: "Across 6 days"
  end

  test "a stat whose plain switch is on is drawn as a plain figure" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "stat_card", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["plain"] = "true"

    render html: drawn_document(added)

    assert_select ".ks-metric-plain"
  end

  test "a stat whose bound value the host does not supply shows its fallback, muted" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "stat_card", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["value"] = { "value" => "reviews", "fallback" => nil }

    render html: drawn_document(added, values: {})

    assert_select ".ks-stat-card-fallback", text: "N/A"
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

  test "a value list bound to a host value the host does not supply draws with no rows" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "value_list", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = { "value" => "billing", "fallback" => nil }

    render html: drawn_document(added, values: {})

    assert_select ".ks-value-list-row", count: 0
  end

  test "a data table bound to a host value the host does not supply draws with no rows" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["items"] = { "value" => "work", "fallback" => nil }

    render html: drawn_document(added, values: {})

    assert_select "tbody td", count: 0
  end

  test "a data table whose total row is bound to a host value the host does not supply draws no total row" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["total"] = { "value" => "totals", "fallback" => nil }

    render html: drawn_document(added, values: {})

    assert_select "tfoot", count: 0
  end

  test "a grouped data table whose subtotals are bound to a host value the host does not supply draws its group headings without subtotals" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["items"] = { "value" => "work", "fallback" => nil }
    fields["columns"] = [ { "key" => "task", "label" => "Task" }, { "key" => "hours", "label" => "Hours" } ]
    fields["group_by"] = "project"
    fields["group_totals"] = { "value" => "subtotals", "fallback" => nil }

    render html: drawn_document(added, values: { "work" => [ { "project" => "Portal", "task" => "Export", "hours" => "2.0" } ] })

    assert_equal [ "Portal", "" ], css_select("tbody tr[data-table-group] th").map { |cell| cell.text.strip }
  end

  test "an element shown only for another value of a host value is not drawn on the live page" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }

    render html: drawn_document(added, values: { "audience" => "client" })

    assert_select ".ks-pages-element", count: 0
  end

  test "a row shown only for another value of a host value is not drawn on the live page" do
    @document["sections"][0]["rows"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }

    render html: drawn_document(@document, values: { "audience" => "client" })

    assert_select ".ks-pages-row", count: 0
  end

  test "a section shown only for another value of a host value is not drawn on the live page" do
    @document["sections"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }

    render html: drawn_document(@document, values: { "audience" => "client" })

    assert_select ".ks-pages-section", count: 0
  end

  test "an element shown only for a value of a host value is drawn on the live page when the host supplies that value" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }

    render html: drawn_document(added, values: { "audience" => "internal" })

    assert_select ".ks-pages-element", count: 1
  end

  test "the builder still draws an element its sample hides, marked as hidden" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }

    render html: drawn_document(added, editing: true, values: { "audience" => "client" })

    assert_select ".ks-pages-element[data-hidden]", count: 1
  end

  test "the builder still draws a row and a section their sample hides, marked as hidden" do
    @document["sections"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }
    @document["sections"][0]["rows"][0]["show_when"] = { "value" => "audience", "equals" => "internal" }

    render html: drawn_document(@document, editing: true, values: { "audience" => "client" })

    assert_select ".ks-pages-section[data-hidden] .ks-pages-row[data-hidden]", count: 1
  end

  test "a section is kept on one printed page" do
    render html: drawn_document(@document)

    assert_select ".ks-pages-section.print\\:break-inside-avoid", count: 1
  end

  test "an element keeps each table row on one printed page" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)

    render html: drawn_document(added)

    assert_includes css_select(".ks-pages-element").first["class"].split, "print:[&_tr]:break-inside-avoid"
  end

  test "an element keeps each label and value row on one printed page" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "value_list", column_id: column_id)

    render html: drawn_document(added)

    assert_includes css_select(".ks-pages-element").first["class"].split, "print:[&_.ks-value-list-row]:break-inside-avoid"
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

  test "a feature with no icon set shows the check mark" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "feature_grid", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["features"] = [ { "title" => "Fast", "description" => "Quick", "icon" => "" } ]

    render html: drawn_document(added)

    assert_select ".ks-feature-card-icon svg path[d='M5 12l5 5L20 7']"
  end

  test "a script typed into a feature's icon is drawn as text and not run" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "feature_grid", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["features"] = [ { "title" => "Fast", "description" => "Quick", "icon" => "<script>alert(1)</script>" } ]

    render html: drawn_document(added)

    assert_equal [ 0, "<script>alert(1)</script>" ], [ css_select(".ks-feature-card-icon script").size, css_select(".ks-feature-card-icon").first.text.strip ]
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

  test "a data table column the editor aligned to the end draws its cells right" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["items"] = { "value" => "work", "fallback" => nil }
    fields["columns"] = [ { "key" => "hours", "label" => "Hours", "align" => "end" }, { "key" => "task", "label" => "Task" } ]

    render html: drawn_document(added, values: { "work" => [ { "task" => "Export", "hours" => "2.0" } ] })

    assert_select "td.text-right", text: "2.0"
  end

  test "a data table groups the host's rows under headings named by the key the editor gave" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["items"] = { "value" => "work", "fallback" => nil }
    fields["columns"] = [ { "key" => "task", "label" => "Task" } ]
    fields["group_by"] = "project"

    render html: drawn_document(added, values: { "work" => [ { "project" => "Portal", "task" => "Export" }, { "project" => "Reporting", "task" => "Charts" } ] })

    assert_equal %w[Portal Export Reporting Charts], css_select("tbody tr").map { |row| row.text.strip }
  end

  test "a data table shows the subtotals the host supplies in each group's heading row" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["items"] = { "value" => "work", "fallback" => nil }
    fields["columns"] = [ { "key" => "task", "label" => "Task" }, { "key" => "hours", "label" => "Hours" } ]
    fields["group_by"] = "project"
    fields["group_totals"] = { "value" => "subtotals", "fallback" => nil }

    render html: drawn_document(added, values: { "work" => [ { "project" => "Portal", "task" => "Export", "hours" => "2.0" } ],
                                                 "subtotals" => { "Portal" => { "hours" => "2.0" } } })

    assert_equal [ "Portal", "2.0" ], css_select("tbody tr[data-table-group] th").map { |cell| cell.text.strip }
  end

  test "a data table ends with a total row showing the values the host supplies" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "data_table", column_id: column_id)
    fields = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]
    fields["items"] = { "value" => "work", "fallback" => nil }
    fields["columns"] = [ { "key" => "task", "label" => "Task" }, { "key" => "hours", "label" => "Hours" } ]
    fields["total"] = { "value" => "totals", "fallback" => nil }

    render html: drawn_document(added, values: { "work" => [ { "task" => "Export", "hours" => "2.0" } ], "totals" => { "task" => "Total", "hours" => "2.0" } })

    assert_equal [ "Total", "2.0" ], css_select("tfoot th").map { |cell| cell.text.strip }
  end

  test "a bar chart draws the bars the host supplies, shading the ones the host marks as shaded" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "bar_chart", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["bars"] = { "value" => "hours", "fallback" => nil }

    render html: drawn_document(added, values: { "hours" => [ { "label" => "Fri", "value" => "2.5" }, { "label" => "Sat", "value" => "1", "shaded" => true } ] })

    assert_equal [ false, true ], css_select("rect.ks-bar-chart-bar").map { |bar| bar["class"].split.include?("ks-bar-chart-bar-shaded") }
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

  test "a paragraph stored as rich text draws its words with each link going to its address" do
    render html: drawn_document(paragraph_document({ "html" => "<p>Founded by <a href=\"/about\">Tyler</a> in 2020</p>" }))

    paragraph = css_select("p.ks-paragraph").first
    assert_equal [ "Founded by Tyler in 2020", "/about" ], [ paragraph.text, paragraph.at_css("a")&.[]("href") ]
  end

  test "a rich paragraph's link to another site opens in a new tab" do
    render html: drawn_document(paragraph_document({ "html" => "<p>Made by <a href=\"https://ty-ler.com\">Tyler</a></p>" }))

    link = css_select("p.ks-paragraph a").first
    assert_equal [ "_blank", "noopener noreferrer" ], [ link["target"], link["rel"] ]
  end

  test "a rich paragraph keeps the line breaks and separate paragraphs typed into it" do
    render html: drawn_document(paragraph_document({ "html" => "<p>First line<br>Second line</p><p>Next paragraph</p>" }))

    assert_equal [ 2, 1 ], [ css_select("p.ks-paragraph").size, css_select("p.ks-paragraph br").size ]
  end

  test "a rich paragraph never draws a script, a style or a tag other than a paragraph, a line break or a link" do
    render html: drawn_document(paragraph_document({ "html" => "<p onclick=\"steal()\">Hi <script>steal()</script><style>p{}</style><b>bold</b> <img src=x onerror=steal()></p>" }))

    assert_equal [ [], "Hi bold", nil ], [ css_select("p.ks-paragraph *").map(&:name), css_select("p.ks-paragraph").first.text.strip, css_select("p.ks-paragraph").first["onclick"] ]
  end

  test "a rich paragraph draws a link whose address would run script as plain words" do
    render html: drawn_document(paragraph_document({ "html" => "<p>Click <a href=\"javascript:steal()\">here</a></p>" }))

    assert_equal [ [], "Click here" ], [ css_select("p.ks-paragraph a").to_a, css_select("p.ks-paragraph").first.text ]
  end

  test "a paragraph saved as plain text with angle brackets draws as the same escaped text" do
    render html: drawn_document(paragraph_document("Use <b> for bold & <a> for links"))

    paragraph = css_select("p.ks-paragraph").first
    assert_equal [ "Use <b> for bold & <a> for links", [] ], [ paragraph.text, paragraph.element_children.to_a ]
  end


  test "a page draws every other element when one element's kind is no longer offered" do
    column = @document["sections"][0]["rows"][0]["columns"][0]
    column["elements"] = [ { "id" => "gone", "key" => "retired_widget", "fields" => {} }, { "id" => "kept", "key" => "heading", "fields" => { "text" => "Still here" } } ]

    render html: drawn_document(@document)

    assert_equal [ 1, "Still here" ], [ css_select(".ks-pages-element").size, css_select(".ks-pages-element").first.text.strip ]
  end


  test "the editor marks an element whose kind is no longer offered" do
    @document["sections"][0]["rows"][0]["columns"][0]["elements"] = [ { "id" => "gone", "key" => "retired_widget", "fields" => {} } ]

    render html: drawn_document(@document, editing: true)

    assert_select "[data-element-id='gone'][data-missing-element]", text: "No longer offered: retired_widget"
  end


  test "drawing a published page reports which page holds an element that is no longer offered" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.document["sections"][0]["rows"][0]["columns"][0]["elements"] = [ { "id" => "gone", "key" => "retired_widget", "fields" => {} } ]
    page.save!
    page.publish
    reports = []
    subscriber = Object.new.tap { |listener| listener.define_singleton_method(:report) { |_error, context:, **| reports << context } }
    Rails.error.subscribe(subscriber)

    render html: drawn_version(page.live_version)

    assert_equal [ { page_id: page.id, element_key: "retired_widget" } ], reports.map { |context| context.slice(:page_id, :element_key) }
  ensure
    Rails.error.unsubscribe(subscriber)
  end

  private

  def paragraph_document(text)
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    KeystoneUi::Pages::Operations.add(@document, "paragraph", column_id: column_id).tap do |added|
      added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["text"] = text
    end
  end

  test "each element on a live drawing carries its element id" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    element_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    render html: drawn_document(document)

    assert_select ".ks-pages-element[data-page-element='#{element_id}']"
  end

  test "a page drawn before element ids were added is drawn again rather than served from its old cached drawing" do
    cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id))
    version = page.publish
    Rails.cache.write([ "keystone_ui_pages", version.id, KeystoneUi::Pages::Operations.digest({}) ], "<div class=\"ks-pages-element\"></div>")

    render html: drawn_version(version)

    assert_select ".ks-pages-element[data-page-element]"
  ensure
    Rails.cache = cache
  end
end

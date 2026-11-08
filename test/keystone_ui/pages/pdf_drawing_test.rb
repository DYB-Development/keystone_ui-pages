# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/pdf_drawing"
require "keystone_ui/pages/catalog"
require "keystone_ui/pages/keystone_elements"

class KeystoneUi::Pages::PdfDrawingTest < ActiveSupport::TestCase
  class RecordingSurface
    attr_reader :drawn

    def initialize
      @drawn = []
    end

    def text(content, size:, **style)
      @drawn << [ :text, content, size, style ]
    end

    def space(token, steps)
      @drawn << [ :space, token, steps ]
    end

    def rich_text(runs, size:, **style)
      @drawn << [ :rich_text, runs, size, style ]
    end

    def box(**style)
      @drawn << [ :box, style ]
      yield
    end

    def boxed_text(content, size:, **style)
      @drawn << [ :boxed_text, content, size, style ]
    end

    def rule(**style)
      @drawn << [ :rule, style ]
    end

    def row(widths, **layout)
      @drawn << [ :row, widths, layout.presence ].compact
      widths.each_index { |index| yield index }
    end

    def table(heading, rows, **style)
      @drawn << [ :table, heading, rows, style ]
    end

    def tables
      @drawn.select { |call| call.first == :table }
    end

    def table_texts
      tables.last.then { |call| [ call[1][:cells].pluck(:text), call[2].map { |table_row| table_row[:cells].pluck(:text) } ] }
    end

    def texts
      @drawn.select { |call| call.first == :text }.map { |call| call[1] }
    end

    def paragraphs
      @drawn.select { |call| call.first == :rich_text }.map { |call| call[1].sum("") { |run| run[:text] } }
    end

    def styles
      @drawn.select { |call| call.first == :text }.map(&:last)
    end
  end

  SERVICE_COLUMNS = [ { "key" => "service", "label" => "Service" }, { "key" => "hours", "label" => "Hours" } ].freeze

  test "the PDF draws each heading and label in the order the page shows them" do
    document = page(
      section(row(column(element("heading", text: "Pricing"), element("label", text: "Per seat")))),
      section(row(column(element("label", text: "Billed monthly"))))
    )

    assert_equal [ "Pricing", "Per seat", "Billed monthly" ], drawn(document).texts
  end

  test "a row's columns are drawn side by side at the widths the page gives them on a wide screen" do
    document = page(section(row(column(wide: "1/4"), column)))

    assert_equal [ :row, [ Rational(1, 4), Rational(1, 2) ] ], drawn(document).drawn.first
  end

  test "a heading or label bound to a host value shows that value, or its fallback when the value is missing" do
    document = page(section(row(column(element("heading", text: { "value" => "client_name", "fallback" => "Client" }),
                                       element("label", text: { "value" => "plan_name", "fallback" => "Your plan" })))))

    assert_equal [ "Acme", "Your plan" ], drawn(document, values: { "client_name" => "Acme" }).texts
  end

  test "a section, row or element hidden by its condition for the values given is left out of the PDF" do
    internal = { "value" => "audience", "equals" => "internal" }
    document = page(
      section(row(column(element("label", text: "Hidden section"))), show_when: internal),
      section(row(column(element("label", text: "Hidden row")), show_when: internal),
              row(column(element("label", text: "Hidden element", show_when: internal), element("label", text: "Shown"))))
    )

    assert_equal [ "Shown" ], drawn(document, values: { "audience" => "public" }).texts
  end

  test "a page holding an element without a PDF drawing is refused with a print failure naming the element" do
    document = page(section(row(column(element("heading", text: "Pricing"), element("code")))))

    error = assert_raises(KeystoneUi::Pages::PrintFailed) { drawn(document) }

    assert_equal "The Code element has no PDF drawing, so this page cannot be drawn as a PDF without Chrome.", error.message
  end

  test "a page holding an element the catalog does not have is refused with a print failure naming the element's key" do
    document = page(section(row(column(element("pricing_table")))))

    error = assert_raises(KeystoneUi::Pages::PrintFailed) { drawn(document) }

    assert_equal "The page holds a pricing_table element, which the catalog does not have, so this page cannot be drawn as a PDF.", error.message
  end

  test "an element whose text holds a character its font cannot draw is refused with a print failure naming the element and the character" do
    document = page(section(row(column(element("heading", text: "Next → step")))))
    surface = RecordingSurface.new
    surface.define_singleton_method(:text) { |*, **| raise KeystoneUi::Pages::PdfSurface::UndrawableCharacter, "→" }

    error = assert_raises(KeystoneUi::Pages::PrintFailed) { KeystoneUi::Pages::PdfDrawing.draw(document, surface) }

    assert_equal "The Heading element holds the character → (U+2192), which its font cannot draw, so this page cannot be drawn as a PDF.", error.message
  end

  test "a heading's note is drawn under its text" do
    document = page(section(row(column(element("heading", text: "Pricing", note: "Updated monthly")))))

    assert_equal [ "Pricing", "Updated monthly" ], drawn(document).texts
  end

  test "a heading is drawn in the font keystone_ui names for headings, at the heading weight" do
    document = page(section(row(column(element("heading", text: "Pricing")))))

    assert_equal({ font: "--ks-font-heading", weight: "--ks-font-weight-heading" }, drawn(document).styles.last.slice(:font, :weight))
  end

  test "a label is drawn in the font keystone_ui names for body text, at its strong weight" do
    document = page(section(row(column(element("label", text: "Per seat")))))

    assert_equal({ font: "--ks-font-body", weight: "--ks-font-weight-strong" }, drawn(document).styles.last.slice(:font, :weight))
  end

  test "a heading is drawn in the text colour keystone_ui gives headings" do
    document = page(section(row(column(element("heading", text: "Pricing")))))

    assert_equal "--ks-color-text", drawn(document).styles.last[:color]
  end

  test "a label and a heading's note are drawn in the muted text colour keystone_ui gives them" do
    document = page(section(row(column(element("heading", text: "Pricing", note: "Updated monthly"), element("label", text: "Per seat")))))

    assert_equal [ "--ks-color-text-muted", "--ks-color-text-muted" ], drawn(document).styles.last(2).pluck(:color)
  end

  test "elements in a column are drawn four of keystone_ui's spacing steps apart, as the page spaces them on screen" do
    document = page(section(row(column(element("heading", text: "Pricing"), element("label", text: "Per seat")))))

    assert_equal [ :row, :text, [ :space, "--ks-spacing", 4 ], :text ], drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "rows in a section are drawn six of keystone_ui's spacing steps apart, as the page spaces them on screen" do
    document = page(section(row(column(element("label", text: "Per seat"))), row(column(element("label", text: "Billed monthly")))))

    assert_equal [ :row, :text, [ :space, "--ks-spacing", 6 ], :row, :text ], drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "headings, a heading's note and a label are drawn at the text sizes keystone_ui gives them" do
    document = page(section(row(column(element("heading", text: "Small", size: "sm"), element("heading", text: "Medium", size: "md"),
                                       element("heading", text: "Large", size: "lg", note: "Updated monthly"), element("label", text: "Per seat")))))

    assert_equal [ "--text-lg", "--text-2xl", "--text-4xl", "--text-sm", "--text-xs" ], drawn(document).drawn.select { |call| call.first == :text }.map { |call| call[2] }
  end

  test "a label is drawn in capitals, as keystone_ui's caption shows it" do
    document = page(section(row(column(element("label", text: "Per seat")))))

    assert drawn(document).styles.last[:uppercase]
  end

  test "a label is drawn with the wider letter spacing keystone_ui's caption gives it" do
    document = page(section(row(column(element("label", text: "Per seat")))))

    assert_equal "--tracking-wider", drawn(document).styles.last[:tracking]
  end

  test "a paragraph stored as rich text is drawn as its paragraphs, with each line break kept" do
    document = page(section(row(column(element("paragraph", text: { "html" => "<p>First line<br>Second line</p><p>Next paragraph</p>" })))))

    assert_equal [ "First line\nSecond line", "Next paragraph" ], drawn(document).paragraphs
  end

  test "a link in a paragraph is drawn with the address it opens" do
    document = page(section(row(column(element("paragraph", text: { "html" => "<p>Made by <a href=\"https://ty-ler.com\">Tyler</a></p>" })))))

    assert_equal [ { text: "Made by " }, { text: "Tyler", link: "https://ty-ler.com" } ], drawn(document).drawn.last[1]
  end

  test "bold and italic marks stored in a paragraph are drawn bold and italic" do
    document = page(section(row(column(element("paragraph", text: { "html" => "<p><strong>Firm</strong> <em>soft</em> <b><i>both</i></b></p>" })))))

    assert_equal [ { text: "Firm", bold: true }, { text: " " }, { text: "soft", italic: true }, { text: " " }, { text: "both", bold: true, italic: true } ], drawn(document).drawn.last[1]
  end

  test "a paragraph stored as plain text is drawn as one paragraph of that text, angle brackets and all" do
    document = page(section(row(column(element("paragraph", text: "Use <b> for bold & <a> for links")))))

    assert_equal [ "Use <b> for bold & <a> for links" ], drawn(document).paragraphs
  end

  test "a paragraph is drawn in keystone_ui's body font and the text colour its paragraph rule gives it" do
    document = page(section(row(column(element("paragraph", text: "Founded in 2020")))))

    assert_equal({ font: "--ks-font-body", color: "--ks-color-text" }, drawn(document).drawn.last.last.slice(:font, :color))
  end

  test "an alert is drawn as its title above its message, or its message alone when it has no title" do
    document = page(section(row(column(element("alert", title: "Heads up", message: "Prices change in May"), element("alert", message: "Saved")))))

    assert_equal [ "Heads up", "Prices change in May", "Saved" ], drawn(document).texts
  end

  test "an alert is drawn on the fill and in the text colour keystone_ui's tokens give its type" do
    document = page(section(row(column(*%w[info success warning error].map { |type| element("alert", title: "Heads up", message: "Read this", type: type) }))))

    drawing = drawn(document).drawn
    assert_equal [ %w[--ks-color-info-50 --ks-color-success-50 --ks-color-warning-50 --ks-color-danger-50],
                   %w[--ks-color-info-800 --ks-color-info-800 --ks-color-success-800 --ks-color-success-800 --ks-color-warning-800 --ks-color-warning-800 --ks-color-danger-800 --ks-color-danger-800] ],
                 [ drawing.select { |call| call.first == :box }.map { |call| call.last[:fill] }, drawing.select { |call| call.first == :text }.map { |call| call.last[:color] } ]
  end

  test "an alert's title is drawn at the heading weight keystone_ui's alert title rule gives it" do
    document = page(section(row(column(element("alert", title: "Heads up", message: "Read this")))))

    assert_equal [ "--ks-font-weight-heading", nil ], drawn(document).styles.pluck(:weight)
  end

  test "an alert's message is drawn one of keystone_ui's spacing steps under its title" do
    document = page(section(row(column(element("alert", title: "Heads up", message: "Read this")))))

    assert_equal [ :row, :box, :text, [ :space, "--ks-spacing", 1 ], :text ], drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "an alert's fill is drawn with the padding and rounded corners keystone_ui's alert rule gives it" do
    document = page(section(row(column(element("alert", message: "Read this")))))

    assert_equal({ padding: [ "--ks-spacing", 4 ], radius: [ "--ks-radius-surface", 0.75 ] }, drawn(document).drawn.find { |call| call.first == :box }.last.except(:fill))
  end

  test "a label and value list is drawn as rows of a label beside its value" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" }, { "label" => "Hours", "value" => "12" } ])))))

    assert_equal [ [ Rational(2, 5), Rational(3, 5) ], "Rate", "$150.00", [ Rational(2, 5), Rational(3, 5) ], "Hours", "12" ],
                 drawn(document).drawn.drop(1).filter_map { |call| { row: call[1], text: call[1] }[call.first] }
  end

  test "a label and value list draws each value from the host's values, or the row's fallback when the value is missing" do
    document = page(section(row(column(element("value_list", rows: { "value" => "billing", "fallback" => nil })))))
    billing = [ { "label" => "Rate", "value" => "$150.00" }, { label: "Reviews", value: nil }, { "label" => "Notes", "value" => "", "fallback" => "None yet" } ]

    assert_equal [ "Rate", "$150.00", "Reviews", "N/A", "Notes", "None yet" ], drawn(document, values: { "billing" => billing }).texts
  end

  test "a label and value list draws its labels and values in the text colours keystone_ui's value list rules give them" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" } ])))))

    assert_equal [ "--ks-color-text-secondary", "--ks-color-text" ], drawn(document).styles.pluck(:color)
  end

  test "a label and value list's total row is drawn at keystone_ui's strong weight with its label in the full text colour" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" }, { "label" => "Total", "value" => "$1,875.00", "total" => "true" } ])))))

    assert_equal [ [ nil, "--ks-color-text-secondary" ], [ nil, "--ks-color-text" ], [ "--ks-font-weight-strong", "--ks-color-text" ], [ "--ks-font-weight-strong", "--ks-color-text" ] ],
                 drawn(document).styles.map { |style| style.values_at(:weight, :color) }
  end

  test "a label and value list set to end-aligned values draws its values aligned to the right" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" } ], align: "end")))))

    assert_equal [ nil, :right ], drawn(document).styles.pluck(:align)
  end

  test "a label and value row's note is drawn under its label at the size and in the muted colour keystone_ui's value list note rule gives it" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "note" => "Per hour", "value" => "$150.00" } ])))))

    assert_equal [ "Per hour", "--text-xs", "--ks-color-text-muted" ], drawn(document).drawn.select { |call| call.first == :text }[1].then { |call| [ call[1], call[2], call[3][:color] ] }
  end

  test "a label and value row is padded above and below by two of keystone_ui's spacing steps, as its row rule pads it" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" } ])))))

    assert_equal [ :row, [ :space, "--ks-spacing", 2 ], :row, :text, :text, [ :space, "--ks-spacing", 2 ] ], drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "label and value rows are divided by a line of keystone_ui's border width and colour, and the first row has none above it" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" }, { "label" => "Hours", "value" => "12" } ])))))

    assert_equal [ :row, :space, :row, :text, :text, :space, [ :rule, { width: "--ks-border-width", color: "--ks-color-border" } ], :space, :row, :text, :text, :space ],
                 drawn(document).drawn.map { |call| call.first == :rule ? call : call.first }
  end

  test "a label and value row draws its value four of keystone_ui's spacing steps from its label, as its row rule spaces them" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" } ])))))

    assert_equal({ gap: [ "--ks-spacing", 4 ] }, drawn(document).drawn.select { |call| call.first == :row }.last[2])
  end

  test "a paragraph's lines are drawn at the relaxed line height keystone_ui's paragraph rule gives them" do
    document = page(section(row(column(element("paragraph", text: "Founded in 2020")))))

    assert_equal "--leading-relaxed", drawn(document).drawn.last.last[:leading]
  end

  test "headings and a heading's note are drawn at the line heights keystone_ui's text sizes give them" do
    document = page(section(row(column(element("heading", text: "Small", size: "sm"), element("heading", text: "Medium", size: "md"),
                                       element("heading", text: "Large", size: "lg", note: "Updated monthly")))))

    assert_equal %w[--text-lg--line-height --text-2xl--line-height --text-4xl--line-height --text-sm--line-height], drawn(document).styles.pluck(:leading)
  end

  test "a label is drawn at the line height keystone_ui's caption text size gives it" do
    document = page(section(row(column(element("label", text: "Per seat")))))

    assert_equal "--text-xs--line-height", drawn(document).styles.last[:leading]
  end

  test "an alert's message is drawn at the line height keystone_ui's small text size gives it" do
    document = page(section(row(column(element("alert", message: "Read this")))))

    assert_equal "--text-sm--line-height", drawn(document).styles.last[:leading]
  end

  test "a label and value row's note is drawn at the line height keystone_ui's extra small text size gives it" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "note" => "Per hour", "value" => "$150.00" } ])))))

    assert_equal "--text-xs--line-height", drawn(document).styles[1][:leading]
  end

  test "an alert's title is drawn at the line height the stylesheet's html rule gives the page" do
    document = page(section(row(column(element("alert", title: "Heads up", message: "Read this")))))

    assert_equal "line-height", drawn(document).styles.first[:leading]
  end

  test "a label and value row's label and value are drawn at the line height the stylesheet's html rule gives the page" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" } ])))))

    assert_equal [ "line-height", "line-height" ], drawn(document).styles.pluck(:leading)
  end

  test "a form, a copy button and a Next page element draw nothing in the PDF and do not refuse it" do
    document = page(section(row(column(element("form"), element("copy_button", text: "ABC123"), element("next_page")))))

    keystone_elements = KeystoneUi::Pages::Catalog.new.tap { |catalog| KeystoneUi::Pages::KeystoneElements.register(catalog) }

    assert_equal [ :row, :space, :space ], KeystoneUi::Pages.stub(:catalog, keystone_elements) { drawn(document) }.drawn.map(&:first)
  end

  test "a button with no address is drawn as its label, in the look keystone_ui's primary medium button rules give it" do
    document = page(section(row(column(element("button", label: "Book a call")))))

    assert_equal [ :boxed_text, "Book a call", "--text-base",
                   { font: "--ks-font-body", weight: "--ks-font-weight-strong", color: "--ks-color-on-accent", leading: "--text-base--line-height",
                     fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ],
                     border: { width: "--ks-border-width-control", color: "--ks-color-on-accent" }, link: nil } ], drawn(document).drawn.last
  end

  test "a button with an address is drawn opening that address when clicked" do
    document = page(section(row(column(element("button", label: "Book a call", href: "https://ty-ler.com/book")))))

    assert_equal "https://ty-ler.com/book", drawn(document).drawn.last.last[:link]
  end

  test "an accordion is drawn as each question with its answer beneath, in the order the page shows them" do
    document = page(section(row(column(element("accordion", items: [ { "question" => "What is it?", "answer" => "A page." }, { "question" => "Who for?", "answer" => "Hosts." } ])))))

    assert_equal [ "What is it?", "A page.", "Who for?", "Hosts." ], drawn(document).texts
  end

  test "an accordion's question is drawn in the look keystone_ui's accordion button rule gives it" do
    document = page(section(row(column(element("accordion", items: [ { "question" => "What is it?", "answer" => "A page." } ])))))

    assert_equal({ font: "--ks-font-body", weight: "--ks-font-weight-heading", color: "--ks-color-text-display", leading: "line-height" }, drawn(document).styles.first)
  end

  test "an accordion's answer is drawn at the size and in the look keystone_ui's accordion answer rule gives it" do
    document = page(section(row(column(element("accordion", items: [ { "question" => "What is it?", "answer" => "A page." } ])))))

    assert_equal [ "--text-sm", { font: "--ks-font-body", color: "--ks-color-text-body", leading: "--text-sm--line-height" } ], drawn(document).drawn.select { |call| call.first == :text }.last.last(2)
  end

  test "each accordion question and its answer are drawn in a box with the border, rounded corners and padding keystone_ui's accordion item and button rules give it" do
    document = page(section(row(column(element("accordion", items: [ { "question" => "What is it?", "answer" => "A page." }, { "question" => "Who for?", "answer" => "Hosts." } ])))))

    item = { padding: [ "--ks-spacing", 6, 4 ], radius: [ "--ks-radius-surface", 1.5 ], border: { width: "--ks-border-width", color: "--ks-color-border-subtle" } }
    assert_equal [ [ :box, item ], :text, :text, [ :box, item ], :text, :text ], drawn(document).drawn.drop(1).reject { |call| call.first == :space }.map { |call| call.first == :box ? call : call.first }
  end

  test "an accordion's answer is drawn four of keystone_ui's spacing steps under its question, as the accordion button pads it" do
    document = page(section(row(column(element("accordion", items: [ { "question" => "What is it?", "answer" => "A page." } ])))))

    assert_equal [ :row, :box, :text, [ :space, "--ks-spacing", 4 ], :text ], drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "accordion items are drawn four of keystone_ui's spacing steps apart, as the accordion rule spaces them, and the first has no space above it" do
    document = page(section(row(column(element("accordion", items: [ { "question" => "What is it?", "answer" => "A page." }, { "question" => "Who for?", "answer" => "Hosts." } ])))))

    gap = [ :space, "--ks-spacing", 4 ]
    assert_equal [ :row, :box, :text, gap, :text, gap, :box, :text, gap, :text ], drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "a table is drawn as a heading row of its column headings and one row per item" do
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: [ { "service" => "Review", "hours" => "4" }, { "service" => "Audit", "hours" => "2" } ])))))

    assert_equal [ %w[Service Hours], [ %w[Review 4], %w[Audit 2] ] ], drawn(document).table_texts
  end

  test "a table whose host value holds no items is drawn as its heading row alone" do
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: { "value" => "lines", "fallback" => nil })))))

    assert_equal [ %w[Service Hours], [] ], drawn(document, values: { "lines" => [] }).table_texts
  end

  test "a table's columns are aligned as keystone_ui's table aligns them, the last to the right unless set to start and any set to end to the right" do
    columns = [ { "key" => "service", "label" => "Service" }, { "key" => "hours", "label" => "Hours", "align" => "end" }, { "key" => "notes", "label" => "Notes", "align" => "start" } ]
    document = page(section(row(column(element("data_table", columns: columns, items: [ { "service" => "Review", "hours" => "4", "notes" => "Done" } ]),
                                       element("data_table", columns: SERVICE_COLUMNS, items: [ { "service" => "Review", "hours" => "4" } ])))))

    assert_equal [ [ %i[left right left], %i[left right left] ], [ %i[left right], %i[left right] ] ],
                 drawn(document).tables.map { |call| [ call[1], *call[2] ].map { |table_row| table_row[:cells].pluck(:align) } }
  end

  test "a table grouped by a key draws each group's name above its rows, with the group's subtotals when they are given" do
    items = [ { "team" => "Ops", "service" => "Review", "hours" => "4" }, { "team" => "Ops", "service" => "Audit", "hours" => "2" }, { "team" => "Sales", "service" => "Pitch", "hours" => "1" } ]
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: items, group_by: "team", group_totals: { "Ops" => { "hours" => "6" } })))))

    assert_equal [ %w[Ops 6], %w[Review 4], %w[Audit 2], [ "Sales", "" ], %w[Pitch 1] ], drawn(document).table_texts.last
  end

  test "a table's total row is drawn as its total row, with each column's total" do
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: [ { "service" => "Review", "hours" => "4" } ], total: { "service" => "Total", "hours" => "4" })))))

    assert_equal %w[Total 4], drawn(document).tables.last.last[:total][:cells].pluck(:text)
  end

  test "a table's heading, group and total rows are drawn on keystone_ui's table head fill and its item rows on the table body fill" do
    items = [ { "team" => "Ops", "service" => "Review", "hours" => "4" } ]
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: items, group_by: "team", total: { "service" => "Total", "hours" => "4" })))))

    table = drawn(document).tables.last
    assert_equal %w[--ks-color-table-head --ks-color-table-head --ks-color-table-body --ks-color-table-head], [ table[1], *table[2], table.last[:total] ].pluck(:fill)
  end

  test "a table's heading, group and total cells are drawn at the weight and in the colour keystone_ui's table header rule gives them" do
    items = [ { "team" => "Ops", "service" => "Review", "hours" => "4" } ]
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: items, group_by: "team", total: { "service" => "Total", "hours" => "4" })))))

    table = drawn(document).tables.last
    header = { weight: "--ks-font-weight-heading", color: "--ks-color-text-heading" }
    assert_equal [ [ header, header ] ] * 3, [ table[1], table[2].first, table.last[:total] ].map { |table_row| table_row[:cells].map { |cell| cell.slice(:weight, :color) } }
  end

  test "a table's item cells are drawn at the weights and in the colours keystone_ui's first, middle and last table cell rules give them" do
    columns = [ { "key" => "service", "label" => "Service" }, { "key" => "notes", "label" => "Notes" }, { "key" => "hours", "label" => "Hours" } ]
    document = page(section(row(column(element("data_table", columns: columns, items: [ { "service" => "Review", "notes" => "Done", "hours" => "4" } ])))))

    assert_equal [ { weight: "--ks-font-weight-medium", color: "--ks-color-text" }, { color: "--ks-color-text-muted" }, { weight: "--ks-font-weight-medium", color: "--ks-color-text" } ],
                 drawn(document).tables.last[2].first[:cells].map { |cell| cell.slice(:weight, :color) }
  end

  test "a table of one column draws it as keystone_ui's table draws a first column, aligned to the left" do
    document = page(section(row(column(element("data_table", columns: [ { "key" => "service", "label" => "Service" } ], items: [ { "service" => "Review" } ])))))

    assert_equal [ :left, :left ], drawn(document).tables.last.then { |call| [ call[1], *call[2] ].map { |table_row| table_row[:cells].first[:align] } }
  end

  test "a table's cells are padded as keystone_ui's first, middle and last table header and cell rules pad them" do
    columns = [ { "key" => "service", "label" => "Service" }, { "key" => "notes", "label" => "Notes" }, { "key" => "hours", "label" => "Hours" } ]
    document = page(section(row(column(element("data_table", columns: columns, items: [ { "service" => "Review", "notes" => "Done", "hours" => "4" } ])))))

    assert_equal [ [ [ "--ks-spacing", 6, 3, 3.5 ], [ "--ks-spacing", 3, 3, 3.5 ], [ "--ks-spacing", 3, 6, 3.5 ] ], [ [ "--ks-spacing", 6, 3, 4 ], [ "--ks-spacing", 3, 3, 4 ], [ "--ks-spacing", 3, 6, 4 ] ] ],
                 drawn(document).tables.last.then { |call| [ call[1], call[2].first ].map { |table_row| table_row[:cells].pluck(:padding) } }
  end

  test "a table is drawn inside the border and rounded corners keystone_ui's table rule gives it, with its rows divided as its table body rule divides them" do
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: [ { "service" => "Review", "hours" => "4" } ])))))

    assert_equal({ border: { width: "--ks-border-width", color: "--ks-color-border" }, radius: [ "--ks-radius-surface", 1 ], divider: { width: "--ks-border-width", color: "--ks-color-divider" } },
                 drawn(document).tables.last.last.except(:total, :parts_divider))
  end

  test "a table's cells are drawn in keystone_ui's body font at the small text size and its line height, as the table's cell classes size them" do
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: [ { "service" => "Review", "hours" => "4" } ])))))

    assert_equal [ { size: "--text-sm", font: "--ks-font-body", leading: "--text-sm--line-height" } ],
                 drawn(document).tables.last.then { |call| [ call[1], *call[2] ].flat_map { |table_row| table_row[:cells].map { |cell| cell.slice(:size, :font, :leading) } } }.uniq
  end

  test "a table's group row is kept on the same page as the first row of its group" do
    items = [ { "team" => "Ops", "service" => "Review", "hours" => "4" } ]
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: items, group_by: "team")))))

    assert_equal [ true, nil ], drawn(document).tables.last[2].pluck(:with_next)
  end

  test "a table whose host value holds no columns draws nothing, as keystone_ui's table shows no headings or cells" do
    document = page(section(row(column(element("data_table", columns: { "value" => "columns", "fallback" => nil }, items: [ { "service" => "Review" } ])))))

    assert_equal [ :row ], drawn(document, values: { "columns" => [] }).drawn.map(&:first)
  end

  test "a table's heading, body and total rows are divided by the one pixel gray line keystone_ui's divide class draws between them" do
    document = page(section(row(column(element("data_table", columns: SERVICE_COLUMNS, items: [ { "service" => "Review", "hours" => "4" } ])))))

    assert_equal({ width: "1px", color: "--color-gray-300" }, drawn(document).tables.last.last[:parts_divider])
  end

  test "a stat is drawn as its label, its value followed by its suffix, and its note" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "4,200", suffix: "USD", note: "Up on last month")))))

    assert_equal [ [ "Revenue", "Up on last month" ], [ "4,200 USD" ] ], drawn(document).then { |surface| [ surface.texts, surface.paragraphs ] }
  end

  test "a stat whose value is missing shows its When missing text in the muted colour keystone_ui's stat fallback rule gives it" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: { "value" => "revenue" }, fallback: "Not yet")))))

    assert_equal [ { text: "Not yet", color: "--ks-color-text-muted" } ], drawn(document).drawn.find { |call| call.first == :rich_text }[1]
  end

  private

  def drawn(document, values: {})
    RecordingSurface.new.tap { |surface| KeystoneUi::Pages::PdfDrawing.draw(document, surface, values: values) }
  end

  def page(*sections)
    { "schema_version" => 1, "sections" => sections }
  end

  def section(*rows, **settings)
    { "id" => SecureRandom.uuid, "rows" => rows }.merge(settings.stringify_keys)
  end

  def row(*columns, **settings)
    { "id" => SecureRandom.uuid, "columns" => columns }.merge(settings.stringify_keys)
  end

  def column(*elements, **settings)
    { "id" => SecureRandom.uuid, "elements" => elements }.merge(settings.stringify_keys)
  end

  def element(key, show_when: nil, **fields)
    { "id" => SecureRandom.uuid, "key" => key, "fields" => fields.stringify_keys, "show_when" => show_when }.compact
  end
end

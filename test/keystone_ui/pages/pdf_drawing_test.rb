# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/pdf_drawing"
require "keystone_ui/pages/catalog"
require "keystone_ui/pages/keystone_elements"

class KeystoneUi::Pages::PdfDrawingTest < ActiveSupport::TestCase
  class RecordingPlot
    LENGTHS = { "--spacing" => 3.0, "--text-xs" => 9.0, "11px" => 8.25, "12px" => 9.0 }.freeze

    attr_reader :calls

    def initialize
      @calls = []
    end

    def width = 500.0
    def height = 200.0

    def points(length)
      LENGTHS.fetch(length) { length.end_with?("px") ? length.to_f * 0.75 : raise(KeyError, length) }
    end

    def text_width(content, size:, font: "--ks-font-body")
      content.to_s.length * points(size) / 2
    end

    def rect(*place, **style)
      @calls << [ :rect, place, style ]
    end

    def line(points, **style)
      @calls << [ :line, points, style ]
    end

    def label(content, *place, **style)
      @calls << [ :label, content, place, style ]
    end
  end

  class RecordingSurface
    attr_reader :laid_out

    def initialize
      @laid_out = []
      @depth = 0
    end

    def drawn
      @laid_out.select { |call, depth| depth.positive? || call.first == :row }.map(&:first)
    end

    def text(content, size:, **style)
      record [ :text, content, size, style ]
    end

    def space(token, steps)
      record [ :space, token, steps ]
    end

    def rich_text(runs, size:, **style)
      record [ :rich_text, runs, size, style ]
    end

    def box(**style)
      record [ :box, style ]
      yield
    end

    def boxed_text(content, size:, **style)
      record [ :boxed_text, content, size, style ]
    end

    def aligned(align)
      record [ :aligned, align ]
      yield
    end

    def together
      record [ :together ]
      yield
      record [ :together_end ]
    end

    def rule(**style)
      record [ :rule, style ]
    end

    def bar(share, **style)
      record [ :bar, share, style ]
    end

    def row(widths, **layout)
      record [ :row, widths, layout.presence ].compact
      @depth += 1
      widths.each_index { |index| yield index }
      @depth -= 1
    end

    def table(heading, rows, **style)
      record [ :table, heading, rows, style ]
    end

    def plot(**style)
      plotted = RecordingPlot.new
      yield plotted
      record [ :plot, style, plotted.calls ]
    end

    def plotted(call = nil)
      drawn.select { |drawn_call| drawn_call.first == :plot }.flat_map(&:last).select { |plot_call| call.nil? || plot_call.first == call }
    end

    def tables
      drawn.select { |call| call.first == :table }
    end

    def table_texts
      tables.last.then { |call| [ call[1][:cells].pluck(:text), call[2].map { |table_row| table_row[:cells].pluck(:text) } ] }
    end

    def texts
      drawn.select { |call| call.first == :text }.map { |call| call[1] }
    end

    def paragraphs
      drawn.select { |call| call.first == :rich_text }.map { |call| call[1].sum("") { |run| run[:text] } }
    end

    def styles
      drawn.select { |call| call.first == :text }.map(&:last)
    end

    private

    def record(call)
      @laid_out << [ call, @depth ]
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

    assert_equal [ Rational(1, 4), Rational(1, 2) ], drawn(document).drawn.first.second
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
    document = page(section(row(column(element("heading", text: "Pricing"), element("testimonial")))))

    error = assert_raises(KeystoneUi::Pages::PrintFailed) { drawn(document) }

    assert_equal "The Testimonial element has no PDF drawing, so this page cannot be drawn as a PDF without Chrome.", error.message
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

    assert_equal [ :row, :text, [ :space, "--ks-spacing", 6 ], :row, :text ], drawn(document).laid_out.map(&:first).reject { |call| call.first.start_with?("together") }.drop(1).map { |call| call.first == :space ? call : call.first }
  end

  test "a section is drawn below the space keystone_ui's small, medium and large section spacing gives it, and medium when it has none" do
    document = page(section(row(column), spacing: "sm"), section(row(column), spacing: "md"), section(row(column), spacing: "lg"), section(row(column)))

    assert_equal [ 4, 6, 8, 6 ], drawn(document).laid_out.map(&:first).select { |call| call.first == :space }.map(&:last)
  end

  test "a section's rows are drawn together, so a section that fits on one page is never split across two" do
    document = page(section(row(column(element("label", text: "Per seat"))), row(column(element("label", text: "Billed monthly")))))

    assert_equal %i[space together row text space row text together_end], drawn(document).laid_out.map { |call, _depth| call.first }.values_at(0, 1, 3, 4, 6, 8, 9, -1)
  end

  test "a shaded section's rows are drawn on keystone_ui's shaded section fill, with no padding, as the page shades it" do
    document = page(section(row(column(element("label", text: "Per seat"))), background: "shaded"))

    assert_equal [ :box, { padding: [ "--ks-spacing", 0 ], fill: "--ks-color-fill-muted" } ], drawn(document).laid_out.map(&:first)[2]
  end

  test "a section with a width setting draws its rows no wider than keystone_ui's page width for that setting" do
    document = page(*%w[sm md lg xl none].map { |width| section(row(column), width: width) })

    assert_equal [ [ "--container-2xl", 1 ], [ "--container-4xl", 1 ], [ "--container-6xl", 1 ], [ "--container-7xl", 1 ] ],
                 drawn(document).laid_out.map(&:first).select { |call| call.first == :box }.map { |call| call.last.fetch(:width) }
  end

  test "a section with a width setting is centred in the padding keystone_ui's page rule and the page's sized section padding give it at the printed page's width" do
    document = page(section(row(column), width: "md"))

    assert_equal({ padding: [ "--ks-spacing", 6, 16 ], align: :center }, drawn(document).laid_out.map(&:first).find { |call| call.first == :box }.last.except(:width))
  end

  test "a row's columns are laid out as the page's grid, the space keystone_ui's small, medium, large and extra large grid gaps give apart, and medium when it has none" do
    document = page(section(*%w[sm md lg xl].map { |gap| row(column, column, gap: gap) }, row(column, column)))

    assert_equal [ 3, 4, 6, 8, 4 ].map { |steps| { gap: [ "--ks-spacing", steps ], grid: true } }, drawn(document).drawn.select { |call| call.first == :row }.map { |call| call.last.slice(:gap, :grid) }
  end

  test "a row's columns are placed at the top, centre or bottom of the row as each column is aligned, and at the top when it has no alignment" do
    document = page(section(row(column(align: "top"), column(align: "center"), column(align: "bottom"), column)))

    assert_equal %i[top center bottom top], drawn(document).drawn.first.last[:align]
  end

  test "an element aligned to the start, centre or end is drawn there in its column, a stretched one across it, and each as its catalog entry aligns it when it has no alignment" do
    document = page(section(row(column(element("label", text: "Start").merge("align" => "start"), element("label", text: "Centre").merge("align" => "center"),
                                       element("label", text: "End").merge("align" => "end"), element("label", text: "Stretch").merge("align" => "stretch"),
                                       element("label", text: "Default"), element("button", label: "Book")))))

    assert_equal %i[start center end start], drawn(document).drawn.select { |call| call.first == :aligned }.map(&:last)
  end

  test "each row of a section is drawn together, so a section taller than a page breaks between its rows" do
    document = page(section(row(column(element("label", text: "Per seat"))), row(column(element("label", text: "Billed monthly")))))

    assert_equal %i[together row text together_end space together row text together_end], drawn(document).laid_out.map(&:first).map(&:first)[2..-2]
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

    assert_equal [ :row, [ :space, "--ks-spacing", 2 ], :row, :text, :text, [ :space, "--ks-spacing", 2 ] ], drawn(document).drawn.reject { |call| call.first.start_with?("together") }.map { |call| call.first == :space ? call : call.first }
  end

  test "label and value rows are divided by a line of keystone_ui's border width and colour, and the first row has none above it" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" }, { "label" => "Hours", "value" => "12" } ])))))

    assert_equal [ :row, :space, :row, :text, :text, :space, [ :rule, { width: "--ks-border-width", color: "--ks-color-border" } ], :space, :row, :text, :text, :space ],
                 drawn(document).drawn.reject { |call| call.first.start_with?("together") }.map { |call| call.first == :rule ? call : call.first }
  end

  test "each label and value row is drawn together with the line above it, so a row is never split across two pages" do
    document = page(section(row(column(element("value_list", rows: [ { "label" => "Rate", "value" => "$150.00" }, { "label" => "Hours", "value" => "12" } ])))))

    assert_equal %i[row together space row text text space together_end together rule space row text text space together_end], drawn(document).drawn.map(&:first)
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

    assert_equal [ :row, :space, :space ], KeystoneUi::Pages.stub(:catalog, keystone_elements) { drawn(document) }.drawn.map(&:first) - [ :aligned ]
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

  test "a stat's value is drawn in the text colour keystone_ui's tone rules give its tone" do
    document = page(section(row(column(*%w[neutral success danger warning info].map { |tone| element("stat_card", value: "12", variant: tone) }))))

    assert_equal %w[--ks-color-text --ks-color-success-600 --ks-color-danger-600 --ks-color-warning-600 --ks-color-info-600],
                 drawn(document).drawn.select { |call| call.first == :rich_text }.map { |call| call.last[:color] }
  end

  test "a stat is drawn in a box with the fill, border, rounded corners and padding keystone_ui's metric card rule gives it" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "12")))))

    assert_equal({ padding: [ "--ks-spacing", 6 ], radius: [ "--ks-radius-surface", 1.5 ], fill: "--ks-color-overlay", border: { width: "--ks-border-width", color: "--ks-color-border" } },
                 drawn(document).drawn.find { |call| call.first == :box }&.last)
  end

  test "a plain stat is drawn without its box, inset by the padding keystone_ui's plain metric rule gives it" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "12", plain: "true")))))

    assert_equal({ padding: [ "--ks-spacing", 4, 0 ] }, drawn(document).drawn.find { |call| call.first == :box }&.last)
  end

  test "a stat's label and note are drawn at the size, weight, colour and line height keystone_ui's stat label and note rules give them" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "12", note: "This month")))))

    assert_equal [ [ "--text-sm", { font: "--ks-font-body", weight: "--ks-font-weight-medium", color: "--ks-color-text-muted", leading: "--text-sm--line-height" } ],
                   [ "--text-sm", { font: "--ks-font-body", color: "--ks-color-text-muted", leading: "--text-sm--line-height" } ] ],
                 drawn(document).drawn.select { |call| call.first == :text }.map { |call| call.last(2) }
  end

  test "a stat's value is drawn at the size, weight and line height keystone_ui's stat value rule gives it" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "12")))))

    assert_equal [ "--text-3xl", { font: "--ks-font-body", weight: "calc(var(--ks-font-weight-heading)+100)", leading: "--text-3xl--line-height" } ],
                 drawn(document).drawn.find { |call| call.first == :rich_text }.then { |call| [ call[2], call.last.except(:color) ] }
  end

  test "a stat's suffix is drawn at the size and in the muted colour keystone_ui's stat suffix rule gives it" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "12", suffix: "hours")))))

    assert_equal({ text: " hours", size: "--text-lg", color: "--ks-color-text-muted" }, drawn(document).drawn.find { |call| call.first == :rich_text }[1].last)
  end

  test "a stat's value and note are each drawn one of keystone_ui's spacing steps under what is above them, with the empty change row's space kept below" do
    document = page(section(row(column(element("stat_card", label: "Revenue", value: "12", note: "This month")))))

    assert_equal [ :row, :box, :text, [ :space, "--ks-spacing", 1 ], :rich_text, [ :space, "--ks-spacing", 1 ], :text, [ :space, "--ks-spacing", 1 ], [ :space, "--spacing", 5 ] ],
                 drawn(document).drawn.map { |call| call.first == :space ? call : call.first }
  end

  test "a figure is drawn as its text in the colour keystone_ui's tone rules give its tone, and a neutral figure in the page's text colour" do
    document = page(section(row(column(*%w[neutral success danger].map { |tone| element("figure", text: "$#{tone.size}", tone: tone) }))))

    assert_equal [ [ "$7", "--ks-color-on-page" ], [ "$7", "--ks-color-success-600" ], [ "$6", "--ks-color-danger-600" ] ],
                 drawn(document).drawn.select { |call| call.first == :text }.map { |call| [ call[1], call.last[:color] ] }
  end

  test "a figure is drawn in the body font at the text size and line height the stylesheet gives the page" do
    document = page(section(row(column(element("figure", text: "$12")))))

    assert_equal [ "--text-base", { font: "--ks-font-body", leading: "line-height" } ], drawn(document).drawn.last.then { |call| [ call[2], call.last.except(:color) ] }
  end

  test "a badge is drawn as its label in a box on the fill and in the text colour keystone_ui's badge rules give its tone" do
    document = page(section(row(column(*%w[neutral success danger warning info].map { |tone| element("badge", label: tone.capitalize, variant: tone) }))))

    assert_equal [ %w[Neutral --ks-color-badge-neutral --ks-color-text-label], %w[Success --ks-color-success-100 --ks-color-success-700],
                   %w[Danger --ks-color-danger-100 --ks-color-danger-700], %w[Warning --ks-color-warning-100 --ks-color-warning-700],
                   %w[Info --ks-color-info-100 --ks-color-info-700] ],
                 drawn(document).drawn.select { |call| call.first == :boxed_text }.map { |call| [ call[1], call.last[:fill], call.last[:color] ] }
  end

  test "a badge is drawn at the size, weight, line height, padding and pill rounding keystone_ui's badge rule gives it" do
    document = page(section(row(column(element("badge", label: "Paid")))))

    assert_equal [ "--text-xs", { font: "--ks-font-body", weight: "--ks-font-weight-medium", leading: "--text-xs--line-height", padding: [ "--ks-spacing", 2, 1 ], radius: [ "--ks-radius-pill", 1 ] } ],
                 drawn(document).drawn.last.then { |call| [ call[2], call.last.except(:fill, :color) ] }
  end

  test "a progress bar is drawn as its label above a bar filled to its value's share of its maximum, rounded to a whole percent as the page rounds it" do
    document = page(section(row(column(element("progress", label: "Hours used", value: "1", max: "3")))))

    assert_equal [ "Hours used", Rational(33, 100) ], drawn(document).drawn.then { |calls| [ calls.find { |call| call.first == :text }[1], calls.find { |call| call.first == :bar }&.at(1) ] }
  end

  test "a progress bar's label is drawn in the look keystone_ui's meter label rule gives it, one of keystone_ui's spacing steps above the bar" do
    document = page(section(row(column(element("progress", label: "Hours used")))))

    assert_equal [ [ :text, "Hours used", "--text-sm", { font: "--ks-font-body", weight: "--ks-font-weight-medium", color: "--ks-color-text-meter-label", leading: "--text-sm--line-height" } ],
                   [ :space, "--ks-spacing", 1 ], :bar ],
                 drawn(document).drawn.drop(1).map { |call| call.first == :bar ? :bar : call }
  end

  test "a progress bar's bar is drawn at the height, pill rounding, track colour and fill colour keystone_ui's progress track and bar rules give it" do
    document = page(section(row(column(element("progress", label: "Hours used")))))

    assert_equal({ height: [ "--spacing", 2 ], radius: [ "--ks-radius-pill", 1 ], track: "--ks-color-track", fill: "--ks-color-meter" }, drawn(document).drawn.last.last)
  end

  test "a bar chart is drawn as one bar per entry, each as tall as its value against the chart's top tick, in the area right of the tick labels and above the bar labels" do
    document = page(section(row(column(element("bar_chart", bars: [ { "label" => "Mon", "value" => "3" }, { "label" => "Tue", "value" => "5" } ])))))

    assert_equal [ [ 65.25, 98.28, 164.5, 83.72 ], [ 300.25, 42.467, 164.5, 139.533 ] ],
                 drawn(document).plotted(:rect).map { |call| call[1].map { |length| length.round(3) } }
  end

  test "a bar chart's bars are drawn in keystone_ui's first chart colour" do
    document = page(section(row(column(element("bar_chart", bars: [ { "label" => "Mon", "value" => "3" } ])))))

    assert_equal [ { color: "--ks-color-chart-1" } ], drawn(document).plotted(:rect).map(&:last)
  end

  test "a bar chart labels each bar beneath it, centred under the bar in keystone_ui's small muted chart text" do
    document = page(section(row(column(element("bar_chart", bars: [ { "label" => "Mon", "value" => "3" }, { "label" => "Tue", "value" => "5" } ])))))

    muted = { size: "--text-xs", color: "--ks-color-text-muted", anchor: :middle }
    assert_equal [ [ :label, "Mon", [ 147.5, 195.5 ], muted ], [ :label, "Tue", [ 382.5, 195.5 ], muted ] ], drawn(document).plotted(:label).select { |call| call.last[:anchor] == :middle }
  end

  test "a bar chart writes each tick of its axis at the tick's height, ending just left of the bars in keystone_ui's small muted chart text" do
    document = page(section(row(column(element("bar_chart", bars: [ { "label" => "Mon", "value" => "3" }, { "label" => "Tue", "value" => "5" } ])))))

    ticks = drawn(document).plotted(:label).select { |call| call.last[:anchor] == :end }
    assert_equal [ [ "0", 182.0 ], [ "2", 126.187 ], [ "4", 70.373 ], [ "6", 14.56 ] ].map { |text, down| [ :label, text, [ 25.5, down ], { size: "--text-xs", color: "--ks-color-text-muted", anchor: :end, baseline: :middle } ] },
                 ticks.map { |call| [ call[0], call[1], [ call[2].first, call[2].last.round(3) ], call[3] ] }
  end

  test "a bar chart draws a grid line in keystone_ui's border colour across the bars at each tick, beneath the bars" do
    document = page(section(row(column(element("bar_chart", bars: [ { "label" => "Mon", "value" => "3" }, { "label" => "Tue", "value" => "5" } ])))))

    assert_equal [ 182.0, 126.187, 70.373, 14.56 ].map { |down| [ :line, [ [ 30.0, down ], [ 500.0, down ] ], { width: "1px", color: "--ks-color-border" } ] } + %i[rect rect],
                 drawn(document).plotted.reject { |call| call.first == :label }.map { |call| call.first == :rect ? :rect : [ call[0], call[1].map { |(across, down)| [ across, down.round(3) ] }, call[2] ] }
  end

  test "a bar chart's shaded bar is drawn in the bar colour at the opacity keystone_ui's shaded bar rule gives it" do
    document = page(section(row(column(element("bar_chart", bars: [ { "label" => "Mon", "value" => "3" }, { "label" => "Sat", "value" => "1", "shaded" => true } ])))))

    assert_equal [ { color: "--ks-color-chart-1" }, { color: "--ks-color-chart-1", opacity: 0.4 } ], drawn(document).plotted(:rect).map(&:last)
  end

  test "a code element is drawn as its code with its line breaks and spaces kept, in the font keystone_ui's code block names" do
    document = page(section(row(column(element("code", code: "def total\n  42\nend")))))

    assert_equal [ "def total\n  42\nend", { font: "--font-mono", preformatted: true } ],
                 drawn(document).drawn.find { |call| call.first == :text }.then { |call| [ call[1], call.last.slice(:font, :preformatted) ] }
  end

  test "a code element's code is drawn at the size, colour and line height keystone_ui's code block rule and classes give it" do
    document = page(section(row(column(element("code", code: "puts 42")))))

    assert_equal [ "--text-sm", { color: "--ks-color-text-code", leading: "--leading-relaxed" } ],
                 drawn(document).drawn.find { |call| call.first == :text }.then { |call| [ call[2], call.last.slice(:color, :leading) ] }
  end

  test "a code element's code is drawn on the code block's fill and padding, inside the border and rounded corners keystone_ui's code rule gives it" do
    document = page(section(row(column(element("code", code: "puts 42")))))

    assert_equal [ [ :box, { padding: [ "--ks-spacing", 0 ], radius: [ "--ks-radius-surface", 1 ], border: { width: "--ks-border-width", color: "--ks-color-border-subtle" }, clip: true } ],
                   [ :box, { padding: [ "--ks-spacing", 4 ], fill: "--ks-color-code" } ], :text ],
                 drawn(document).drawn.drop(1).map { |call| call.first == :text ? :text : call }
  end

  test "a code element's caption is drawn above its code, as the page shows it, in the look keystone_ui's code caption rule gives it with its line beneath" do
    document = page(section(row(column(element("code", code: "puts 42", caption: "total.rb")))))

    assert_equal [ [ :box, { padding: [ "--ks-spacing", 4, 2 ], fill: "--ks-color-fill-muted" } ],
                   [ :text, "total.rb", "--text-xs", { font: "--font-mono", color: "--ks-color-text-display-muted", leading: "--text-xs--line-height" } ],
                   [ :rule, { width: "--ks-border-width", color: "--ks-color-border-subtle" } ], [ :box, { padding: [ "--ks-spacing", 4 ], fill: "--ks-color-code" } ] ],
                 drawn(document).drawn.drop(2).first(4)
  end

  test "a hero is drawn as its badge, its title and its subtitle, in the order the page shows them" do
    document = page(section(row(column(element("hero", badge: "New", title: "Quotes in minutes", subtitle: "Build a quote from your price list.")))))

    assert_equal [ "New", "Quotes in minutes", "Build a quote from your price list." ],
                 drawn(document).drawn.select { |call| %i[text boxed_text].include?(call.first) }.map(&:second)
  end

  test "a hero's title is drawn at the size, weight, colour, letter spacing and line height keystone_ui's hero title rule and classes give it at the printed page's width" do
    document = page(section(row(column(element("hero", title: "Quotes in minutes")))))

    assert_equal [ "--text-5xl", { font: "--ks-font-body", weight: "calc(var(--ks-font-weight-heading)+100)", color: "--ks-color-text-display", tracking: "--tracking-tight", leading: "--text-5xl--line-height" } ],
                 drawn(document).drawn.find { |call| call[1] == "Quotes in minutes" }.then { |call| [ call[2], call.last.except(:align) ] }
  end

  test "a hero's subtitle is drawn at the size, colour and line height keystone_ui's hero subtitle rule and classes give it, no wider than its large width limit" do
    document = page(section(row(column(element("hero", title: "Quotes in minutes", subtitle: "Build a quote from your price list.")))))

    assert_equal [ [ :box, { padding: [ "--ks-spacing", 0 ], width: [ "--container-lg", 1 ] } ],
                   [ :text, "Build a quote from your price list.", "--text-lg", { font: "--ks-font-body", color: "--ks-color-text-display-muted", leading: "--text-lg--line-height" } ] ],
                 drawn(document).drawn.each_cons(2).find { |_box, call| call[1] == "Build a quote from your price list." }.map { |call| [ *call.first(call.size - 1), call.last.except(:align) ] }
  end

  test "a hero's badge is drawn as its text in a pill with the fill, border, padding and text colour keystone_ui's hero badge rule gives it" do
    document = page(section(row(column(element("hero", badge: "New", title: "Quotes in minutes")))))

    assert_equal [ :boxed_text, "New", "--text-sm", { font: "--ks-font-body", color: "--ks-color-link", leading: "--text-sm--line-height", fill: "--ks-color-tint",
                                                      padding: [ "--ks-spacing", 4, 1.5 ], radius: [ "--ks-radius-pill", 1 ], border: { width: "--ks-border-width", color: "--ks-color-tint-border" } } ],
                 drawn(document).drawn.find { |call| call[1] == "New" }.then { |call| [ *call.first(3), call.last.except(:align) ] }
  end

  test "a centred hero draws its badge, title and subtitle centred, and a split hero draws them from the left, as the page lays them out at the printed page's width" do
    aligned = %w[centered split].map do |layout|
      document = page(section(row(column(element("hero", layout: layout, badge: "New", title: "Quotes in minutes", subtitle: "Build a quote.")))))
      drawn(document).drawn.select { |call| %i[boxed_text text].include?(call.first) || (call.first == :box && call.last.key?(:width)) }.map { |call| call.last[:align] }
    end

    assert_equal [ [ :center ] * 4, [ nil ] * 4 ], aligned
  end

  test "a hero is drawn inside the space and padding keystone_ui's hero rules give it, its badge, title, subtitle and empty actions row eight spacing steps apart" do
    document = page(section(row(column(element("hero", badge: "New", title: "Quotes in minutes", subtitle: "Build a quote.")))))

    assert_equal [ [ :space, "--ks-spacing", 24 ], [ :box, { padding: [ "--ks-spacing", 6, 24 ] } ], :boxed_text, [ :space, "--ks-spacing", 8 ], :text,
                   [ :space, "--ks-spacing", 8 ], :box, :text, [ :space, "--ks-spacing", 8 ] ],
                 drawn(document).drawn.drop(1).map { |call| call.first == :space || call.last.keys == [ :padding ] ? call : call.first }
  end

  test "a call to action is drawn as its title, its subtitle and its text, in the order the page shows them" do
    document = page(section(row(column(element("cta_banner", title: "Ready to start?", subtitle: "Book a call this week.", text: "No card needed.")))))

    assert_equal [ "Ready to start?", "Book a call this week.", "No card needed." ], drawn(document).texts
  end

  test "a call to action is drawn in a box with the fill, border, rounded corners and padding keystone_ui's call to action rule gives it at the printed page's width" do
    document = page(section(row(column(element("cta_banner", title: "Ready to start?")))))

    assert_equal [ :box, { padding: [ "--ks-spacing", 6, 12 ], radius: [ "--ks-radius-surface", 2 ], fill: "--ks-color-fill-muted",
                           border: { width: "--ks-border-width", color: "--ks-color-border-subtle" } } ], drawn(document).drawn.second
  end

  test "a call to action's title is drawn centred at the size, weight, colour, letter spacing and line height keystone_ui's call to action title rule and classes give it" do
    document = page(section(row(column(element("cta_banner", title: "Ready to start?")))))

    assert_equal [ "--text-4xl", { font: "--ks-font-body", weight: "calc(var(--ks-font-weight-heading)+100)", color: "--ks-color-text-display", tracking: "--tracking-tight",
                                   leading: "--text-4xl--line-height", align: :center } ], drawn(document).drawn.find { |call| call.first == :text }.last(2)
  end

  test "a call to action's subtitle is drawn centred in the look keystone_ui's call to action subtitle rule and classes give it, spaced from its title and text as the page spaces them" do
    document = page(section(row(column(element("cta_banner", title: "Ready to start?", subtitle: "Book a call this week.", text: "No card needed.")))))

    assert_equal [ [ :space, "--ks-spacing", 4 ], [ :box, { padding: [ "--ks-spacing", 0 ], width: [ "--container-2xl", 1 ], align: :center } ],
                   [ :text, "Book a call this week.", "--text-lg", { font: "--ks-font-body", color: "--ks-color-text-display-muted", leading: "--text-lg--line-height", align: :center } ],
                   [ :space, "--ks-spacing", 8 ], :text ],
                 drawn(document).drawn.drop(3).map { |call| call[1] == "No card needed." ? :text : call }
  end

  test "a call to action's text is drawn centred in the page's own text size, line height and colour, which it takes from the page as the call to action sets none" do
    document = page(section(row(column(element("cta_banner", title: "Ready to start?", text: "No card needed.")))))

    assert_equal [ "--text-base", { font: "--ks-font-body", color: "--ks-color-on-page", leading: "line-height", align: :center } ], drawn(document).drawn.last.last(2)
  end

  test "a card is drawn as its title, its summary and its link text, in the order the page shows them" do
    document = page(section(row(column(element("card", title: "Pricing", summary: "Plans for every team.", link: "https://ty-ler.com/pricing", cta: "See plans")))))

    assert_equal [ "Pricing", "Plans for every team.", "See plans" ],
                 drawn(document).drawn.filter_map { |call| call[1] if call.first == :text || call.first == :rich_text }.map { |content| content.is_a?(Array) ? content.sum("") { |run| run[:text] } : content }
  end

  test "a card's link text is drawn opening the card's address when clicked" do
    document = page(section(row(column(element("card", title: "Pricing", link: "https://ty-ler.com/pricing", cta: "See plans")))))

    assert_equal [ { text: "See plans", link: "https://ty-ler.com/pricing" } ], drawn(document).drawn.find { |call| call.first == :rich_text }.second
  end

  test "a card is drawn in a box with the fill, border, rounded corners and padding keystone_ui's card rules give it at the printed page's width" do
    document = page(section(row(column(element("card", title: "Pricing")))))

    assert_equal [ :box, { padding: [ "--ks-spacing", 6, 6 ], radius: [ "--ks-radius-surface", 1 ], fill: "--ks-color-surface",
                           border: { width: "--ks-border-width", color: "--ks-color-border" } } ], drawn(document).drawn.second
  end

  test "a card's title, summary and link text are drawn in the looks keystone_ui's card title, summary and link rules give them, spaced as the card's body and link rows space them" do
    document = page(section(row(column(element("card", title: "Pricing", summary: "Plans for every team.", link: "https://ty-ler.com/pricing", cta: "See plans")))))

    assert_equal [ [ :text, "Pricing", "--text-lg", { font: "--ks-font-heading", weight: "--ks-font-weight-heading", color: "--ks-color-text", leading: "--text-lg--line-height" } ],
                   [ :space, "--ks-spacing", 1 ],
                   [ :text, "Plans for every team.", "--text-sm", { font: "--ks-font-body", color: "--ks-color-text-muted", leading: "--text-sm--line-height" } ],
                   [ :space, "--ks-spacing", 4 ],
                   [ :rich_text, [ { text: "See plans", link: "https://ty-ler.com/pricing" } ], "--text-sm",
                     { font: "--ks-font-body", weight: "--ks-font-weight-medium", color: "--ks-color-link", leading: "--text-sm--line-height" } ] ],
                 drawn(document).drawn.drop(2)
  end

  test "an info block is drawn as its summary with its detail shown in full beneath it, as the page shows them once opened" do
    document = page(section(row(column(element("info", summary: "How hours are counted", detail: "Hours are counted to the quarter hour.\nTravel is not counted.")))))

    assert_equal [ "How hours are counted", "Hours are counted to the quarter hour. Travel is not counted." ], drawn(document).texts
  end

  test "an info block's summary and detail are each drawn in the box keystone_ui's info popup rules give them, at their own widths, the detail two spacing steps under the summary" do
    document = page(section(row(column(element("info", summary: "How hours are counted", detail: "To the quarter hour.")))))
    popup = { padding: [ "--ks-spacing", 3 ], radius: [ "--ks-radius-surface", 1 ], fill: "--ks-color-overlay", border: { width: "--ks-border-width", color: "--ks-color-border" } }

    assert_equal [ [ :box, popup.merge(width: [ "--spacing", 64 ]) ], :text, [ :space, "--ks-spacing", 2 ], [ :box, popup.merge(width: [ "--spacing", 80 ]) ], :text ],
                 drawn(document).drawn.drop(1).map { |call| call.first == :text ? :text : call }
  end

  test "an info block's summary and detail are drawn at the size, colour and line height keystone_ui's info popup rules and classes give them" do
    document = page(section(row(column(element("info", summary: "How hours are counted", detail: "To the quarter hour.")))))

    assert_equal [ [ "--text-sm", { font: "--ks-font-body", color: "--ks-color-on-overlay-muted", leading: "--text-sm--line-height" } ] ] * 2,
                 drawn(document).drawn.select { |call| call.first == :text }.map { |call| call.last(2) }
  end

  test "a feature grid is drawn as its title, its subtitle and each feature's title and description, in the order the page shows them" do
    features = [ { "title" => "Fast", "description" => "Pages load quickly." }, { "title" => "Clear", "description" => "Every page reads plainly." } ]
    document = page(section(row(column(element("feature_grid", title: "Why teams choose us", subtitle: "Three reasons.", features: features)))))

    assert_equal [ "Why teams choose us", "Three reasons.", "Fast", "Pages load quickly.", "Clear", "Every page reads plainly." ], drawn(document).texts
  end

  test "a feature grid's title and subtitle are drawn centred in the looks keystone_ui's feature grid title and subtitle rules give them, spaced as the page spaces them" do
    document = page(section(row(column(element("feature_grid", title: "Why teams choose us", subtitle: "Three reasons.")))))

    assert_equal [ [ :text, "Why teams choose us", "--text-4xl", { font: "--ks-font-body", weight: "calc(var(--ks-font-weight-heading)+100)", color: "--ks-color-text-display",
                                                                    tracking: "--tracking-tight", leading: "--text-4xl--line-height", align: :center } ],
                   [ :space, "--ks-spacing", 4 ], [ :box, { padding: [ "--ks-spacing", 0 ], width: [ "--container-2xl", 1 ], align: :center } ], :text, [ :space, "--ks-spacing", 16 ] ],
                 drawn(document).drawn.drop(2).first(5).map { |call| call[1] == "Three reasons." ? :text : call }
  end

  test "a feature grid's features are drawn two to a row of equal columns, six spacing steps apart across and down, as keystone_ui's feature grid lays them out at the printed page's width" do
    features = %w[Fast Clear Yours].map { |title| { "title" => title, "description" => "#{title} pages." } }
    document = page(section(row(column(element("feature_grid", title: "Why teams choose us", features: features)))))

    assert_equal [ [ :row, [ Rational(1, 2), Rational(1, 2) ], { gap: [ "--ks-spacing", 6 ], grid: true } ], [ :space, "--ks-spacing", 6 ],
                   [ :row, [ Rational(1, 2), Rational(1, 2) ], { gap: [ "--ks-spacing", 6 ], grid: true } ] ],
                 drawn(document).drawn.drop(1).select { |call| call.first == :row || call == [ :space, "--ks-spacing", 6 ] }
  end

  test "a feature is drawn in the box of keystone_ui's feature card, stretched to its row's height as the grid stretches it, its title and description in the looks the feature card's title and description rules give them" do
    document = page(section(row(column(element("feature_grid", title: "Why teams choose us", features: [ { "title" => "Fast", "description" => "Pages load quickly." } ])))))

    assert_equal [ [ :box, { padding: [ "--ks-spacing", 6 ], radius: [ "--ks-radius-surface", 1.5 ], fill: "--ks-color-raised", border: { width: "--ks-border-width", color: "--ks-color-border-subtle" },
                             stretch: true } ],
                   [ :text, "Fast", "--text-lg", { font: "--ks-font-body", weight: "--ks-font-weight-heading", color: "--ks-color-text-display", leading: "--text-lg--line-height" } ],
                   [ :space, "--ks-spacing", 2 ],
                   [ :text, "Pages load quickly.", "--text-sm", { font: "--ks-font-body", color: "--ks-color-text-display-muted", leading: "--text-sm--line-height" } ] ],
                 drawn(document).drawn.reject { |call| call.first == :together_end }.last(4)
  end

  test "a feature grid's title and subtitle are drawn together with its first row of features, so they are never printed on a page apart from it" do
    features = %w[Fast Clear Yours].map { |title| { "title" => title, "description" => "#{title} pages." } }
    document = page(section(row(column(element("feature_grid", title: "Why teams choose us", subtitle: "Three reasons.", features: features)))))

    assert_equal %i[together text space box text space row box text space text box text space text together_end space row box text space text],
                 drawn(document).drawn.drop(1).map(&:first)
  end

  test "every element the page shows as ordinary text joins a stored line break into a space, as the browser does, and only code keeps its line breaks" do
    broken = "Two\nlines"
    elements = [ element("heading", text: broken, note: broken), element("label", text: broken), element("paragraph", text: broken), element("alert", title: broken, message: broken),
                 element("value_list", rows: [ { "label" => broken, "value" => broken, "note" => broken } ]), element("button", label: broken), element("accordion", items: [ { "question" => broken, "answer" => broken } ]),
                 element("data_table", columns: [ { "key" => "name", "label" => broken } ], items: [ { "name" => broken } ]), element("stat_card", label: broken, value: broken, suffix: broken, note: broken),
                 element("figure", text: broken), element("badge", label: broken), element("progress", label: broken), element("hero", badge: broken, title: broken, subtitle: broken),
                 element("cta_banner", title: broken, subtitle: broken, text: broken), element("card", title: broken, summary: broken, cta: broken), element("info", summary: broken, detail: broken),
                 element("feature_grid", title: broken, subtitle: broken, features: [ { "title" => broken, "description" => broken } ]), element("code", code: broken) ]
    strings = ->(drawn) { drawn.is_a?(String) ? [ drawn ] : Array(drawn.is_a?(Hash) ? drawn.values : drawn).flat_map { |part| part.is_a?(String) || part.is_a?(Array) || part.is_a?(Hash) ? strings.(part) : [] } }

    assert_equal [ broken ], strings.(drawn(page(section(row(column(*elements))))).drawn).select { |text| text.include?("\n") }.uniq
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

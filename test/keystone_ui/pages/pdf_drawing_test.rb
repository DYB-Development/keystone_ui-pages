# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_drawing"

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

    def row(widths)
      @drawn << [ :row, widths ]
      widths.each_index { |index| yield index }
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

    assert_equal({ font: "--ks-font-body", color: "--ks-color-text" }, drawn(document).drawn.last.last)
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

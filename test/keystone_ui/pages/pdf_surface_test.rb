# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_surface"
require "keystone_ui/pages/pdf_look"

class KeystoneUi::Pages::PdfSurfaceTest < ActiveSupport::TestCase
  LONG_SERVICE = "Consulting hours for the quarterly review of accounts, the year end close, and the board pack prepared for the March meeting"

  test "a row drawn inside a column of another row starts each of its columns at the same height" do
    surface = KeystoneUi::Pages::PdfSurface.new(KeystoneUi::Pages::PdfLook.new(":root{--text-base:1rem;--ks-color-text:#000000;--ks-font-body:sans-serif}"))

    surface.row([ 1 ]) { surface.row([ Rational(1, 2), Rational(1, 2) ]) { |index| surface.text(%w[Left Right][index], size: "--text-base") } }

    assert_equal 1, heights(surface.render).values_at("Left", "Right").uniq.size
  end

  test "lines of text drawn with a line height token are spaced that many text sizes apart" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.text("First\nSecond", size: "--text-base", leading: "--leading-loose")

    assert_in_delta 24.0, heights(surface.render).values_at("First", "Second").map(&:to_f).reduce(:-), 0.001
  end

  test "lines of rich text drawn with a line height token are spaced that many text sizes apart" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.rich_text([ { text: "First\nSecond" } ], size: "--text-base", leading: "--leading-loose")

    assert_in_delta 24.0, heights(surface.render).values_at("First", "Second").map(&:to_f).reduce(:-), 0.001
  end

  test "a boxed line of text is drawn inset from its fill's left edge by the padding's horizontal steps" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ])

    assert_equal 48.0, lefts(surface.render)["Book a call"]
  end

  test "a boxed line of text is drawn on a fill as wide as the text and its horizontal padding" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ])

    assert_in_delta 58.692 + 24, fill_widths(surface.render).first, 0.001
  end

  test "a boxed line of text given an address opens that address when clicked" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ], link: "https://ty-ler.com/book")

    assert_includes surface.render, "/URI (https://ty-ler.com/book)"
  end

  test "a boxed line of text given a border is stroked in the border's colour at the border's width" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ],
                                      border: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_match(/0\.0 0\.0 0\.0 SCN\n1\.5 w\n/, surface.render)
  end

  test "a boxed line of text given a border is inset by the border's width as well as its padding" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ],
                                      border: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_equal 49.5, lefts(surface.render)["Book a call"]
  end

  test "a box given a border and no fill is stroked in the border's colour at the border's width" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 4 ], radius: [ "--ks-radius-control", 1 ], border: { width: "--ks-border-width-control", color: "--ks-color-text" }) do
      surface.text("Answer", size: "--text-base")
    end

    assert_match(/0\.0 0\.0 0\.0 SCN\n1\.5 w\n/, surface.render)
  end

  test "a box's content is inset from its left edge by the padding's horizontal steps" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 6, 4 ], radius: [ "--ks-radius-control", 1 ]) { surface.text("Book a call", size: "--text-base") }

    assert_equal 54.0, lefts(surface.render)["Book a call"]
  end

  test "a box given a border insets its content by the border's width as well as its padding" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 6, 4 ], radius: [ "--ks-radius-control", 1 ], border: { width: "--ks-border-width-control", color: "--ks-color-text" }) do
      surface.text("Book a call", size: "--text-base")
    end

    assert_equal 55.5, lefts(surface.render)["Book a call"]
  end

  test "a line of text drawn with a line height token sits with the space its line height leaves split evenly above and below its letters" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.text("Book a call", size: "--text-base", leading: "--leading-loose")

    assert_in_delta 756 - (24 - 11.1) / 2 - 8.616, heights(surface.render)["Book a call"].to_f, 0.001
  end

  test "text drawn after a line of text with a line height token starts one line height lower" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.text("First", size: "--text-base", leading: "--leading-loose")
    surface.text("Second", size: "--text-base", leading: "--leading-loose")

    assert_in_delta 24.0, heights(surface.render).values_at("First", "Second").map(&:to_f).reduce(:-), 0.001
  end

  test "text drawn after a line of rich text with a line height token starts one line height lower" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.rich_text([ { text: "First" } ], size: "--text-base", leading: "--leading-loose")
    surface.text("Second", size: "--text-base", leading: "--leading-loose")

    assert_in_delta 24.0, heights(surface.render).values_at("First", "Second").map(&:to_f).reduce(:-), 0.001
  end

  test "text holding a character its font cannot draw is refused naming the character" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    error = assert_raises(KeystoneUi::Pages::PdfSurface::UndrawableCharacter) { surface.text("Next → step", size: "--text-base") }

    assert_equal "→", error.character
  end

  test "rich text holding a character its font cannot draw is refused naming the character" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    error = assert_raises(KeystoneUi::Pages::PdfSurface::UndrawableCharacter) { surface.rich_text([ { text: "Next " }, { text: "→ step", bold: true } ], size: "--text-base") }

    assert_equal "→", error.character
  end

  test "a table draws its heading row above its rows, each row under the one before" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Name"), [ table_row("First"), table_row("Second") ], **table_look)

    assert_equal %w[Name First Second], heights(surface.render).sort_by { |_text, height| -height.to_f }.map(&:first)
  end

  test "a table cell's text is inset from the cell's left edge by its padding's left steps" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Name"), [], **table_look)

    assert_equal 54.0, lefts(surface.render)["Name"]
  end

  test "a table's column is wide enough for its widest cell's text on one line when the table has room for it" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service", "Hours"), [ table_row("Consulting hours for the quarterly review of accounts", "4") ], **table_look)

    assert_includes lefts(surface.render).keys, "Consulting hours for the quarterly review of accounts"
  end

  test "a table too wide for its column keeps each column wide enough for its longest word and wraps the rest" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service", "Hours"), [ table_row(LONG_SERVICE, "4") ], **table_look)

    assert_includes lefts(surface.render).keys, "Hours"
  end

  test "a table whose words are too wide for its column is drawn within that column" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ Rational(1, 4), Rational(3, 4) ]) do |index|
      surface.table(table_row("Reconciliation", "Depreciation", "Amortisation"), [], **table_look) if index.zero?
    end

    assert_operator lefts(surface.render).values.max, :<, 36 + 135
  end

  test "a table cell's text too long for its cell wraps onto more lines, and the next row starts under its last line" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service", "Hours"), [ table_row(LONG_SERVICE, "4"), table_row("Review", "2") ], **table_look)

    drawn = heights(surface.render).transform_values(&:to_f)
    last_line = drawn.select { |text, _height| LONG_SERVICE.end_with?(text) && text.length > 1 && text != LONG_SERVICE }.values.first
    assert_in_delta 12 + 13.872 + 12, last_line - drawn["Review"], 0.001
  end

  test "a table's total row is drawn under all of its rows" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), [ table_row("Review"), table_row("Audit") ], total: table_row("Total"), **table_look)

    assert_equal %w[Service Review Audit Total], heights(surface.render).sort_by { |_text, height| -height.to_f }.map(&:first)
  end

  test "a table row given a fill is drawn on that fill across the table's whole width and the row's height" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service", fill: "--ks-color-accent"), [], **table_look)

    assert_match(/0\.145\d* 0\.388\d* 0\.92\d* scn\n36\.0 718\.128 540\.0 37\.872 re\nf/, surface.render)
  end

  test "a table's rows are divided by a line of the divider's width and colour, with none above the first row" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), [ table_row("Review"), table_row("Audit") ], **table_look, divider: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_equal 1, surface.render.scan(/0\.0 0\.0 0\.0 scn\n36\.0 [\d.]+ 540\.0 1\.5 re\nf/).size
  end

  test "a table given a border insets its rows by the border's width" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), [], **table_look, border: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_equal 55.5, lefts(surface.render)["Service"]
  end

  test "a table given a border is stroked round its rows in the border's colour at the border's width" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), [], **table_look, border: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_match(/0\.0 0\.0 0\.0 SCN\n1\.5 w\n/, surface.render)
  end

  test "a table longer than a page continues on the next page with its heading row drawn again at the top" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), Array.new(25) { |index| table_row("Review #{index}") }, **table_look)

    assert_equal [ 1, 1 ], pages(surface.render).map { |page| heights(page).keys.count("Service") }
  end

  test "a table that starts part way down a page continues at the top of the next page's margin" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ 1 ]) do
      surface.text("Introduction", size: "--text-base")
      surface.space("--ks-spacing", 40)
      surface.table(table_row("Service"), Array.new(25) { |index| table_row("Review #{index}") }, **table_look)
    end

    assert_equal 735.384, heights(pages(surface.render).last)["Service"].to_f
  end

  test "a table row that does not fit in the space left on a page is drawn whole on the next page" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.space("--ks-spacing", 10)
    surface.table(table_row("Service"), Array.new(20) { table_row("Begins\nEnds") }, **table_look)

    assert_equal [ true, true ], pages(surface.render).map { |page| page.scan("<426567696e73>").size == page.scan("<456e6473>").size }
  end

  test "a bordered table that runs onto the next page is stroked round its part on each page" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), Array.new(25) { |index| table_row("Review #{index}") }, **table_look, border: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_equal [ 1, 1 ], pages(surface.render).map { |page| page.scan(/0\.0 0\.0 0\.0 SCN\n1\.5 w\n/).size }
  end

  test "a table's total row that does not fit on the page is drawn on the next page under the heading row" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), Array.new(18) { |index| table_row("Review #{index}") }, total: table_row("Total"), **table_look)

    assert_equal [ [ "Service" ], [ "Service", "Total" ] ], pages(surface.render).map { |page| heights(page).keys & [ "Service", "Total" ] }
  end

  test "a table whose heading row and first row do not fit in the space left on a page starts on the next page" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.space("--ks-spacing", 223)
    surface.table(table_row("Service"), [ table_row("Review") ], **table_look)

    assert_equal 1, pages(surface.render).sum { |page| heights(page).keys.count("Service") }
  end

  test "a row's later column starts on the page the row starts on when an earlier column runs onto the next page" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ Rational(1, 2), Rational(1, 2) ]) do |index|
      index.zero? ? surface.table(table_row("Service"), Array.new(25) { |row| table_row("Review #{row}") }, **table_look) : surface.text("Side", size: "--text-base")
    end

    assert_includes heights(pages(surface.render).first).keys, "Side"
  end

  test "what follows a row is drawn under the column that ends lowest on the row's last page" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ Rational(1, 2), Rational(1, 2) ]) do |index|
      surface.space("--ks-spacing", 200) if index.zero?
      surface.table(table_row("Service"), Array.new(25) { |row| table_row("Review #{row}") }, **table_look) unless index.zero?
    end
    surface.text("After", size: "--text-base")

    drawn = heights(pages(surface.render).last).transform_values(&:to_f)
    assert_in_delta 12 + 13.872, drawn["Review 24"] - drawn["After"], 0.001
  end

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-base:1rem;--leading-loose:2;--ks-spacing:0.25rem;--ks-radius-control:0.5rem;--ks-border-width-control:2px;--ks-color-accent:#2563EB;--ks-color-text:#000000;--ks-font-body:sans-serif;--ks-border-width:0px;--ks-color-border:#D1D5DB;--ks-radius-surface:0.5rem}")
  end

  def table_row(*texts, fill: nil)
    { cells: texts.map { |text| { text: text, size: "--text-base", padding: [ "--ks-spacing", 6, 3, 4 ] } }, fill: fill }
  end

  def table_look
    { border: { width: "--ks-border-width", color: "--ks-color-border" }, radius: [ "--ks-radius-surface", 1 ], divider: { width: "--ks-border-width", color: "--ks-color-border" } }
  end

  def fill_widths(pdf)
    pdf.scan(/scn\n((?:[\d. ]+ [mlc]\n)+)h\nf\n/).map { |(path)| path.scan(/[\d.]+/).each_slice(2).map { |left, _| left.to_f }.minmax.then { |least, most| most - least } }
  end

  def lefts(pdf)
    pdf.scan(/([\d.]+) [\d.]+ Td\n[^\n]*\n\[([^\]]*)\] TJ/).to_h { |left, text| [ shown(text), left.to_f ] }
  end

  def heights(pdf)
    pdf.scan(/[\d.]+ ([\d.]+) Td\n[^\n]*\n\[([^\]]*)\] TJ/).to_h { |height, text| [ shown(text), height ] }
  end

  def pages(pdf)
    pdf.split("endstream").select { |stream| stream.include?(" Td\n") }
  end

  def shown(kerned)
    kerned.scan(/<(\h+)>/).flatten.join.then { |text| [ text ].pack("H*") }
  end
end

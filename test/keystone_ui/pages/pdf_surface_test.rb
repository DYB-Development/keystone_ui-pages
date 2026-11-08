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

  test "a row laid out as a grid shares its gaps between its columns, so columns of equal shares are equally wide" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ Rational(1, 2), Rational(1, 2) ], gap: [ "--ks-spacing", 6 ], grid: true) { |index| surface.text(%w[Fast Clear][index], size: "--text-base") }

    assert_equal 36.0 + (540 - 18) / 2 + 18, lefts(surface.render)["Clear"]
  end

  test "a column in a row laid out as a grid spans its share of a grid whose tracks are split by the gap, so unequal shares sit as the page's twelve-column grid places them" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ Rational(1, 3), Rational(2, 3) ], gap: [ "--ks-spacing", 6 ], grid: true) { |index| surface.text(%w[Narrow Wide][index], size: "--text-base") }

    assert_equal 36.0 + ((540 - 11 * 18) / 12.0 * 4 + 3 * 18) + 18, lefts(surface.render)["Wide"]
  end

  test "boxes that stretch in a row laid out as a grid are drawn as tall as the row's tallest column" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ Rational(1, 2), Rational(1, 2) ], gap: [ "--ks-spacing", 6 ], grid: true) do |index|
      surface.box(padding: [ "--ks-spacing", 4 ], radius: [ "--ks-radius-control", 1 ], fill: "--ks-color-accent", stretch: true) { surface.text([ "Fast", "Clear\nPlain\nShort" ][index], size: "--text-base") }
    end

    assert_equal 1, fill_heights(surface.render).map { |height| height.round(3) }.uniq.size
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

  test "a run of rich text given its own text size is drawn at that size, and the runs beside it at the paragraph's size" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.rich_text([ { text: "42" }, { text: " hours", size: "--text-lg" } ], size: "--text-base")

    assert_equal [ "12", "13.5" ], surface.render.scan(%r{/F[\d.]+ ([\d.]+) Tf}).flatten
  end

  test "a run of rich text given its own colour is drawn in that colour" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.rich_text([ { text: "42" }, { text: " hours", color: "--ks-color-accent" } ], size: "--text-base", color: "--ks-color-text")

    assert_match(/0\.145\d* 0\.388\d* 0\.92\d* scn\n/, surface.render)
  end

  test "rich text given a bold weight token draws all of its runs bold" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.rich_text([ { text: "42" } ], size: "--text-base", weight: "--ks-font-weight-strong")

    assert_includes surface.render, "/Helvetica-Bold"
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

  test "a boxed line of text rounded more than its height allows is rounded into a pill as wide as the text and its horizontal padding" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-pill", 1 ])

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

  test "a boxed line of text aligned to the centre is drawn with its fill centred in the width it is drawn in" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.boxed_text("Book a call", size: "--text-base", fill: "--ks-color-accent", padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-control", 1 ], align: :center)

    assert_in_delta 36 + (540 - (58.692 + 24)) / 2 + 12, lefts(surface.render)["Book a call"], 0.001
  end

  test "a boxed line of text on a translucent fill is filled at the fill colour's opacity" do
    surface = KeystoneUi::Pages::PdfSurface.new(KeystoneUi::Pages::PdfLook.new(":root{--text-sm:.875rem;--ks-spacing:.25rem;--ks-radius-pill:calc(infinity * 1px);--ks-color-tint:#3b82f633;--ks-color-text:#000000;--ks-font-body:sans-serif}"))

    surface.boxed_text("New", size: "--text-sm", fill: "--ks-color-tint", padding: [ "--ks-spacing", 4, 1.5 ], radius: [ "--ks-radius-pill", 1 ])

    assert_match(%r{/ca 0\.2\b}, surface.render)
  end

  test "a boxed line of text given a translucent border is stroked at the border colour's opacity" do
    surface = KeystoneUi::Pages::PdfSurface.new(KeystoneUi::Pages::PdfLook.new(":root{--text-sm:.875rem;--ks-spacing:.25rem;--ks-radius-pill:calc(infinity * 1px);--ks-border-width:1px;" \
                                                                               "--ks-color-tint:#3b82f6;--ks-color-tint-border:#3b82f633;--ks-color-text:#000000;--ks-font-body:sans-serif}"))

    surface.boxed_text("New", size: "--text-sm", fill: "--ks-color-tint", padding: [ "--ks-spacing", 4, 1.5 ], radius: [ "--ks-radius-pill", 1 ],
                              border: { width: "--ks-border-width", color: "--ks-color-tint-border" })

    assert_match(%r{/CA 0\.2\b}, surface.render)
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

  test "a box given a width narrower than the width it is drawn in is filled that wide" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 3 ], width: [ "--ks-spacing", 64 ], radius: [ "--ks-radius-control", 1 ], fill: "--ks-color-accent") { surface.text("Revenue", size: "--text-base") }

    assert_in_delta 192.0, fill_widths(surface.render).first, 0.001
  end

  test "a box narrower than the width it is drawn in and aligned to the centre is drawn centred in that width" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 0 ], width: [ "--ks-spacing", 64 ], align: :center) { surface.text("Revenue", size: "--text-base") }

    assert_equal 36.0 + (540 - 192) / 2, lefts(surface.render)["Revenue"]
  end

  test "a box that clips its content clips what is drawn inside it to the rounded corners inside its border" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 0 ], radius: [ "--ks-radius-control", 1 ], border: { width: "--ks-border-width-control", color: "--ks-color-text" }, clip: true) do
      surface.box(padding: [ "--ks-spacing", 4 ], fill: "--ks-color-accent") { surface.text("puts 42", size: "--text-base") }
    end

    assert_match(/ c\nh\nW n\n[^W]*scn\n(?:[\d. ]+ [mlc]\n)+h\nf\n/, surface.render)
  end

  test "a box that clips its content strokes its border over what is drawn inside it" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 0 ], radius: [ "--ks-radius-control", 1 ], border: { width: "--ks-border-width-control", color: "--ks-color-text" }, clip: true) do
      surface.box(padding: [ "--ks-spacing", 4 ], fill: "--ks-color-accent") { surface.text("puts 42", size: "--text-base") }
    end

    assert_match(/h\nf\n.*1\.5 w\n/m, surface.render)
  end

  test "a box that clips its content inside a column strokes its border at the top of the box, level with its clipped content" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ 1 ]) do
      surface.box(padding: [ "--ks-spacing", 0 ], radius: [ "--ks-radius-control", 1 ], border: { width: "--ks-border-width-control", color: "--ks-color-text" }, clip: true) do
        surface.box(padding: [ "--ks-spacing", 4 ], fill: "--ks-color-accent") { surface.text("puts 42", size: "--text-base") }
      end
    end

    assert_in_delta 0.75, surface.render.then { |pdf| pdf[/1\.5 w\n[\d.]+ ([\d.]+) m/, 1].to_f - pdf[/q\n[\d.]+ ([\d.]+) m\n/, 1].to_f }, 0.001
  end

  test "a box given no fill, border or rounding insets its content by its padding alone" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 4, 0 ]) { surface.text("Revenue", size: "--text-base") }

    assert_equal 48.0, lefts(surface.render)["Revenue"]
  end

  test "a box given a border insets its content by the border's width as well as its padding" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.box(padding: [ "--ks-spacing", 6, 4 ], radius: [ "--ks-radius-control", 1 ], border: { width: "--ks-border-width-control", color: "--ks-color-text" }) do
      surface.text("Book a call", size: "--text-base")
    end

    assert_equal 55.5, lefts(surface.render)["Book a call"]
  end

  test "a bar is drawn as a track across the whole width with its fill over the share of the width it is given" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.bar(Rational(1, 4), height: [ "--ks-spacing", 2 ], radius: [ "--ks-radius-pill", 1 ], track: "--ks-color-border", fill: "--ks-color-accent")

    assert_equal [ 540.0, 135.0 ], fill_widths(surface.render).map { |width| width.round(3) }
  end

  test "a bar given no share is drawn as its track alone" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.bar(0, height: [ "--ks-spacing", 2 ], radius: [ "--ks-radius-pill", 1 ], track: "--ks-color-border", fill: "--ks-color-accent")

    assert_no_match(/0\.145\d* 0\.388\d* 0\.92\d* scn\n/, surface.render)
  end

  test "text drawn after a bar starts the bar's height lower" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.text("First", size: "--text-base")
    surface.bar(1, height: [ "--ks-spacing", 2 ], radius: [ "--ks-radius-pill", 1 ], track: "--ks-color-border", fill: "--ks-color-accent")
    surface.text("Second", size: "--text-base")

    assert_in_delta 6.0 + 13.872, heights(surface.render).values_at("First", "Second").map(&:to_f).reduce(:-), 0.001
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

  test "preformatted text keeps the spaces at the start of each line" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.text("def total\n  42", size: "--text-base", preformatted: true)

    assert_includes lefts(surface.render).keys, "  42".encode(Encoding::Windows_1252).b
  end

  test "preformatted text draws a tab as the spaces up to the next tab stop the stylesheet's tab size sets" do
    surface = KeystoneUi::Pages::PdfSurface.new(KeystoneUi::Pages::PdfLook.new("html{tab-size:4}:root{--text-base:1rem;--ks-color-text:#000000;--ks-font-body:sans-serif}"))

    surface.text("ab\t42", size: "--text-base", preformatted: true)

    assert_includes lefts(surface.render).keys, "ab  42"
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

  test "a box that does not fit in the space left on a page is drawn whole at the top of the next page's margin" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ 1 ]) do
      surface.text("Introduction", size: "--text-base")
      surface.space("--ks-spacing", 200)
      surface.box(padding: [ "--ks-spacing", 4 ], radius: [ "--ks-radius-control", 1 ], fill: "--ks-color-accent") { surface.text(Array.new(10) { |line| "Line #{line}" }.join("\n"), size: "--text-base") }
    end

    assert_equal 735.384, heights(pages(surface.render).last)["Line 0"].to_f
  end

  test "what is drawn together that does not fit in the space left on a page starts at the top of the next page's margin" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.row([ 1 ]) do
      surface.text("Introduction", size: "--text-base")
      surface.space("--ks-spacing", 200)
      surface.together do
        surface.text("Why teams choose us", size: "--text-base")
        surface.text(Array.new(10) { |line| "Line #{line}" }.join("\n"), size: "--text-base")
      end
    end

    assert_equal 747.384, heights(pages(surface.render).last)["Why teams choose us"].to_f
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

  test "a table cell holding a character its font cannot draw is refused naming the character" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    error = assert_raises(KeystoneUi::Pages::PdfSurface::UndrawableCharacter) { surface.table(table_row("Service"), [ table_row("Next → step") ], **table_look) }

    assert_equal "→", error.character
  end

  test "a table too wide for its column keeps on one line each column whose text fits its share of the width, and wraps the rest" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service", "Notes", "Hours"), [ table_row("Review 12", LONG_SERVICE, "4") ], **table_look)

    assert_includes lefts(surface.render).keys, "Review 12"
  end

  test "a table row kept with the next row is drawn on the next page when the row after it does not fit" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    rows = Array.new(17) { |index| table_row("Review #{index}") } + [ table_row("Group").merge(with_next: true), table_row("Last") ]
    surface.table(table_row("Service"), rows, **table_look)

    assert_equal [ [], [ "Group", "Last" ] ], pages(surface.render).map { |page| heights(page).keys & [ "Group", "Last" ] }
  end

  test "a table cell shorter than its row is centred in the row from top to bottom" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Begins\nEnds", "Middle"), [], **table_look)

    drawn = heights(surface.render).transform_values(&:to_f)
    assert_in_delta 13.872 / 2, drawn["Begins"] - drawn["Middle"], 0.001
  end

  test "a table draws a line of its parts divider's width and colour under its heading row and above its total row" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service"), [ table_row("Review"), table_row("Audit") ], total: table_row("Total"), **table_look,
                  parts_divider: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_equal 2, surface.render.scan(/0\.0 0\.0 0\.0 scn\n36\.0 [\d.]+ 540\.0 1\.5 re\nf/).size
  end

  test "a table's row fills are clipped to the rounded corners inside its border" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.table(table_row("Service", fill: "--ks-color-accent"), [], **table_look, border: { width: "--ks-border-width-control", color: "--ks-color-text" })

    assert_match(/ c\n(?:h\n)?W n\n[^W]*scn\n37\.5 [\d.]+ 537\.0 [\d.]+ re\nf\n/, surface.render)
  end

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-base:1rem;--text-lg:1.125rem;--leading-loose:2;--ks-spacing:0.25rem;--ks-radius-control:0.5rem;--ks-border-width-control:2px;--ks-color-accent:#2563EB;--ks-color-text:#000000;--ks-font-body:sans-serif;--ks-border-width:0px;--ks-color-border:#D1D5DB;--ks-radius-surface:0.5rem;--ks-radius-pill:calc(infinity * 1px);--ks-font-weight-strong:600}")
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

  def fill_heights(pdf)
    pdf.scan(/scn\n((?:[\d. ]+ [mlc]\n)+)h\nf\n/).map { |(path)| path.scan(/[\d.]+/).each_slice(2).map { |_, height| height.to_f }.minmax.then { |least, most| most - least } }
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

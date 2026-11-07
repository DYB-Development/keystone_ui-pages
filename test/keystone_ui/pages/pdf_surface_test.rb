# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_surface"
require "keystone_ui/pages/pdf_look"

class KeystoneUi::Pages::PdfSurfaceTest < ActiveSupport::TestCase
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

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-base:1rem;--leading-loose:2;--ks-spacing:0.25rem;--ks-radius-control:0.5rem;--ks-color-accent:#2563EB;--ks-color-text:#000000;--ks-font-body:sans-serif}")
  end

  def fill_widths(pdf)
    pdf.scan(/scn\n((?:[\d. ]+ [mlc]\n)+)h\nf\n/).map { |(path)| path.scan(/[\d.]+/).each_slice(2).map { |left, _| left.to_f }.minmax.then { |least, most| most - least } }
  end

  def lefts(pdf)
    pdf.scan(/([\d.]+) [\d.]+ Td\n[^\n]*\n\[<(\h+)>\] TJ/).to_h { |left, text| [ [ text ].pack("H*"), left.to_f ] }
  end

  def heights(pdf)
    pdf.scan(/[\d.]+ ([\d.]+) Td\n[^\n]*\n\[<(\h+)>\] TJ/).to_h { |height, text| [ [ text ].pack("H*"), height ] }
  end
end

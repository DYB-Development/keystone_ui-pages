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

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-base:1rem;--leading-loose:2;--ks-color-text:#000000;--ks-font-body:sans-serif}")
  end

  def heights(pdf)
    pdf.scan(/[\d.]+ ([\d.]+) Td\n[^\n]*\n\[<(\h+)>\] TJ/).to_h { |height, text| [ [ text ].pack("H*"), height ] }
  end
end

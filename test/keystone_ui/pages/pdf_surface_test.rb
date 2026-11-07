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

  private

  def heights(pdf)
    pdf.scan(/[\d.]+ ([\d.]+) Td\n[^\n]*\n\[<(\h+)>\] TJ/).to_h { |height, text| [ [ text ].pack("H*"), height ] }
  end
end

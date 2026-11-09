# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_surface"
require "keystone_ui/pages/pdf_look"

class KeystoneUi::Pages::PdfPlotTest < ActiveSupport::TestCase
  test "a rectangle is filled in its colour at its place measured from the plot's top left" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| plot.rect(10, 20, 30, 40, color: "--ks-color-accent") }

    assert_match(/0\.0 0\.0 1\.0 scn\n46\.0 696\.0 30\.0 40\.0 re\nf/, surface.render)
  end

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-xs:0.75rem;--ks-spacing:0.25rem;--ks-color-accent:#0000FF;--ks-color-text:#000000;--ks-font-body:sans-serif}")
  end
end

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

  test "a rectangle given an opacity is filled at that opacity" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| plot.rect(10, 20, 30, 40, color: "--ks-color-accent", opacity: 0.4) }

    assert_match(%r{/ca 0\.4\b}, surface.render)
  end

  test "a line is stroked in its colour and width through its points measured from the plot's top left" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| plot.line([ [ 0, 10 ], [ 20, 30 ], [ 40, 0 ] ], width: "2px", color: "--ks-color-accent") }

    assert_match(/0\.0 0\.0 1\.0 SCN\n1\.5 w\n36\.0 746\.0 m\n56\.0 726\.0 l\n76\.0 756\.0 l\nS/, surface.render)
  end

  test "a line given a dash is stroked in dashes and gaps of the lengths it names" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| plot.line([ [ 0, 10 ], [ 40, 0 ] ], width: "2px", color: "--ks-color-accent", dash: "6px") }

    assert_match(/\[4\.5 4\.5\] 0\.0 d\n36\.0 746\.0 m/, surface.render)
  end

  test "a label is written in its colour and size with its baseline at its place measured from the plot's top left" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| plot.label("Mon", 10, 20, size: "--text-xs", color: "--ks-color-accent") }

    assert_match(/0\.0 0\.0 1\.0 scn\n.*BT\n46\.0 736\.0 Td\n\/F1\.0 9 Tf\n\[<4d6f6e>\] TJ/m, surface.render)
  end

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-xs:0.75rem;--ks-spacing:0.25rem;--ks-color-accent:#0000FF;--ks-color-text:#000000;--ks-font-body:sans-serif}")
  end
end

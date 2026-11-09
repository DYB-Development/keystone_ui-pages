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

  test "a label anchored to its middle or its end is written centred on or ending at its place" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) do |plot|
      plot.label("Mon", 100, 20, size: "--text-xs", color: "--ks-color-accent", anchor: :middle)
      plot.label("Tue", 100, 20, size: "--text-xs", color: "--ks-color-accent", anchor: :end)
    end

    width = ->(text) { Prawn::Document.new.width_of(text, size: 9) }
    assert_equal [ 136 - width.("Mon") / 2, 136 - width.("Tue") ].map { |left| left.round(3) }, lefts(surface.render).values_at("Mon", "Tue").map { |left| left.round(3) }
  end

  test "a label set on its middle or top has its letters centred on or hanging from its place" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    surface.plot(height: [ "--ks-spacing", 40 ]) do |plot|
      plot.label("Mon", 10, 20, size: "--text-xs", color: "--ks-color-accent", baseline: :middle)
      plot.label("Tue", 10, 20, size: "--text-xs", color: "--ks-color-accent", baseline: :top)
    end

    assert_equal [ 736 - (6.462 - 1.863) / 2, 736 - 6.462 ].map { |height| height.round(3) }, heights(surface.render).values_at("Mon", "Tue").map { |height| height.round(3) }
  end

  test "a plot measures how wide a label is written at a size in a font" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    measured = nil
    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| measured = plot.text_width("Wednesday", size: "--text-xs") }

    assert_in_delta Prawn::Document.new.width_of("Wednesday", size: 9), measured, 0.001
  end

  test "a plot reads a length from a keystone_ui token or as written" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    measured = nil
    surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| measured = [ plot.points("--ks-spacing"), plot.points("6px") ] }

    assert_equal [ 3.0, 4.5 ], measured
  end

  test "a label holding a character its font cannot draw is refused naming the character" do
    surface = KeystoneUi::Pages::PdfSurface.new(look)

    error = assert_raises(KeystoneUi::Pages::PdfSurface::UndrawableCharacter) do
      surface.plot(height: [ "--ks-spacing", 40 ]) { |plot| plot.label("Next → step", 0, 0, size: "--text-xs", color: "--ks-color-accent") }
    end

    assert_equal "→", error.character
  end

  private

  def look
    KeystoneUi::Pages::PdfLook.new(":root{--text-xs:0.75rem;--ks-spacing:0.25rem;--ks-color-accent:#0000FF;--ks-color-text:#000000;--ks-font-body:sans-serif}")
  end

  def lefts(pdf)
    pdf.scan(/([\d.]+) [\d.]+ Td\n[^\n]*\n\[([^\]]*)\] TJ/).to_h { |left, text| [ shown(text), left.to_f ] }
  end

  def heights(pdf)
    pdf.scan(/[\d.]+ ([\d.]+) Td\n[^\n]*\n\[([^\]]*)\] TJ/).to_h { |height, text| [ shown(text), height.to_f ] }
  end

  def shown(kerned)
    kerned.scan(/<(\h+)>/).flatten.join.then { |text| [ text ].pack("H*") }
  end
end

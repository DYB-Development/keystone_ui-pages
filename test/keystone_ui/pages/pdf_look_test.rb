# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/pdf_look"

class KeystoneUi::Pages::PdfLookTest < ActiveSupport::TestCase
  test "a colour token is read through the variables it names into the hex colour the PDF draws with" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--color-surface-900:#18181b;--ks-color-text:var(--color-surface-900)}")

    assert_equal "18181B", look.color("--ks-color-text")
  end

  test "an oklch colour is turned into the hex colour it names" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--ks-color-danger:oklch(57.7% .245 27.325)}")

    assert_equal "E7000B", look.color("--ks-color-danger")
  end

  test "a host's own value for a token outside any layer is taken over keystone_ui's value in a layer, wherever it sits in the stylesheet" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--ks-color-text:#112233}@layer base{:root{--ks-color-text:#18181b}}")

    assert_equal "112233", look.color("--ks-color-text")
  end

  test "the look named takes its own token values over the stylesheet's root values, and another look's values are left out" do
    stylesheet = ':root[data-look="calm"]{--ks-color-text:#223344}:root[data-look="loud"]{--ks-color-text:#ff0000}:root{--ks-color-text:#18181b}'

    assert_equal "223344", KeystoneUi::Pages::PdfLook.new(stylesheet, look: "calm").color("--ks-color-text")
  end

  test "a token value set only for a screen or a dark scheme is left out, so the PDF keeps the light mode value" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--ks-color-text:#18181b}@media (prefers-color-scheme:dark){:root{--ks-color-text:#ffffff}}")

    assert_equal "18181B", look.color("--ks-color-text")
  end

  test "a token naming a variable the stylesheet does not set takes the fallback given beside it" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--ks-color-text:var(--color-missing, var(--color-ink))}:root{--color-ink:#112233}")

    assert_equal "112233", look.color("--ks-color-text")
  end

  test "a weight token is read as the number it names" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--font-weight-semibold:600;--ks-font-weight-heading:var(--font-weight-semibold)}")

    assert_equal 600, look.weight("--ks-font-weight-heading")
  end

  test "a length token in rem is read as the points it prints at, a rem being sixteen CSS pixels of three quarters of a point" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--spacing:.25rem;--ks-spacing:var(--spacing)}")

    assert_equal 3.0, look.points("--ks-spacing")
  end

  test "a font token naming only system fonts, with no font files, prints in Helvetica" do
    look = KeystoneUi::Pages::PdfLook.new(':root{--ks-font-body:-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif}')

    assert_equal "Helvetica", look.font("--ks-font-body").name
  end

  test "a font the stylesheet loads from files prints from the TrueType copies served beside them, in regular, bold and italic" do
    served = { "/Inter-Regular.ttf" => "/public/Inter-Regular.ttf", "/Inter-Bold.ttf" => "/public/Inter-Bold.ttf", "/Inter-Italic.ttf" => "/public/Inter-Italic.ttf" }
    look = KeystoneUi::Pages::PdfLook.new(":root{--ks-font-body:Inter, sans-serif}" \
                                          '@font-face{font-family:Inter;font-style:normal;font-weight:400;src:url("/Inter-Regular.woff2") format("woff2")}' \
                                          '@font-face{font-family:Inter;font-style:normal;font-weight:700;src:url("/Inter-Bold.woff2") format("woff2")}' \
                                          '@font-face{font-family:Inter;font-style:italic;font-weight:400;src:url("/Inter-Italic.woff2") format("woff2")}',
                                          font_files: ->(url) { served[url] })

    assert_equal({ normal: "/public/Inter-Regular.ttf", bold: "/public/Inter-Bold.ttf", italic: "/public/Inter-Italic.ttf" }, look.font("--ks-font-body").files)
  end

  test "a font the stylesheet loads from files with no TrueType copy served is refused with a print failure naming the font" do
    look = KeystoneUi::Pages::PdfLook.new(':root{--ks-font-body:Inter}@font-face{font-family:Inter;src:url("/Inter.woff2") format("woff2")}')

    error = assert_raises(KeystoneUi::Pages::PrintFailed) { look.font("--ks-font-body") }

    assert_equal "The PDF needs a TrueType copy of the Inter font at /Inter.ttf, beside the font file the stylesheet loads, and none is served.", error.message
  end

  test "a font token set to inherit takes the font the page's html element is given" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--default-font-family:Inter;--ks-font-body:inherit}html,:host{font-family:var(--default-font-family,sans-serif)}" \
                                          '@font-face{font-family:Inter;src:url("/Inter.woff2") format("woff2")}',
                                          font_files: ->(url) { "/public#{url}" })

    assert_equal "Inter", look.font("--ks-font-body").name
  end

  test "the host's look is read from the stylesheet the gem prints with, in the default look the host names" do
    configuration = KeystoneUi::Configuration.new.tap do |config|
      config.register_look :calm, "calm.css"
      config.default_look = :calm
    end
    stylesheet = ':root{--ks-color-text:#18181b}:root[data-look="calm"]{--ks-color-text:#223344}'

    color = KeystoneUi.stub(:configuration, configuration) do
      KeystoneUi::Pages::PdfDocument.stub(:stylesheet, stylesheet) { KeystoneUi::Pages::PdfLook.host.color("--ks-color-text") }
    end

    assert_equal "223344", color
  end

  test "the host's font is printed from the TrueType copy in its public folder" do
    Dir.mktmpdir do |public_folder|
      FileUtils.touch(File.join(public_folder, "Inter.ttf"))
      stylesheet = ':root{--ks-font-body:Inter}@font-face{font-family:Inter;src:url("/Inter.woff2") format("woff2")}'

      files = Rails.stub(:public_path, Pathname(public_folder)) do
        KeystoneUi::Pages::PdfDocument.stub(:stylesheet, stylesheet) { KeystoneUi::Pages::PdfLook.host.font("--ks-font-body").files }
      end

      assert_equal File.join(public_folder, "Inter.ttf"), files[:normal]
    end
  end

  test "the host's font is printed from the TrueType copy among its assets when the stylesheet loads the font from its assets" do
    stylesheet = ':root{--ks-font-body:Inter}@font-face{font-family:Inter;src:url("/assets/fonts/Inter.woff2") format("woff2")}'
    asset = Struct.new(:path).new(Pathname("/app/assets/fonts/Inter.ttf"))
    load_path = Rails.application.assets.load_path

    files = load_path.stub(:find, ->(logical_path) { asset if logical_path == "fonts/Inter.ttf" }) do
      KeystoneUi::Pages::PdfDocument.stub(:stylesheet, stylesheet) { KeystoneUi::Pages::PdfLook.host.font("--ks-font-body").files }
    end

    assert_equal "/app/assets/fonts/Inter.ttf", files[:normal]
  end

  test "a letter spacing token in em is read as the points it adds between letters at a text size" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--tracking-wider:.05em}")

    assert_equal 0.5, look.points("--tracking-wider", size: 10)
  end
end

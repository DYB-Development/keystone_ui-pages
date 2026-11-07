# frozen_string_literal: true

require "test_helper"
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
end

# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_look"

class KeystoneUi::Pages::PdfLookTest < ActiveSupport::TestCase
  test "a colour token is read through the variables it names into the hex colour the PDF draws with" do
    look = KeystoneUi::Pages::PdfLook.new(":root{--color-surface-900:#18181b;--ks-color-text:var(--color-surface-900)}")

    assert_equal "18181B", look.color("--ks-color-text")
  end
end

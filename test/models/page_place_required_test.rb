# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PagePlaceRequiredTest < ActiveSupport::TestCase
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a page with no place is refused when the host has registered places" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")

    assert_not KeystoneUi::Pages::Page.new(name: "Pricing", slug: "pricing").valid?
  end

  test "a page with no place is accepted when the host has registered no places" do
    assert KeystoneUi::Pages::Page.new(name: "Pricing", slug: "pricing").valid?
  end
end

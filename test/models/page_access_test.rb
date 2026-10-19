# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageAccessTest < ActiveSupport::TestCase
  test "a page keeps the place it is created with" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "client_portal")

    assert_equal "client_portal", page.reload.place
  end

  test "a page cannot be created with a place the host does not name" do
    KeystoneUi::Pages.places = { "client_portal" => "Client portal" }

    page = KeystoneUi::Pages::Page.new(name: "Pricing", slug: "pricing", place: "intranet")

    assert_not page.valid?
  ensure
    KeystoneUi::Pages.places = nil
  end

  test "a page keeps the access exception it is given" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", access_exception: "public_preview")

    assert_equal "public_preview", page.reload.access_exception
  end
end

# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageAccessTest < ActiveSupport::TestCase
  test "a page keeps the place it is created with" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "client_portal")

    assert_equal "client_portal", page.reload.place
  end
end

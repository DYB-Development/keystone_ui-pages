# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::DemoAccessTest < ActiveSupport::TestCase
  test "the demo refuses a client portal page to an anonymous visitor" do
    page = KeystoneUi::Pages::Page.new(place: "client_portal")

    assert_not DemoAccess.allows?(page, "visitor")
  end

  test "the demo shows a client portal page to a signed-in client" do
    page = KeystoneUi::Pages::Page.new(place: "client_portal")

    assert DemoAccess.allows?(page, "signed_in_client")
  end

  test "the demo shows a client portal page with the public preview exception to an anonymous visitor" do
    page = KeystoneUi::Pages::Page.new(place: "client_portal", access_exception: "public_preview")

    assert DemoAccess.allows?(page, "visitor")
  end

  test "the demo refuses a paid content page to a signed-in client who has not purchased" do
    page = KeystoneUi::Pages::Page.new(place: "paid_content")

    assert_not DemoAccess.allows?(page, "signed_in_client")
  end

  test "the test environment leaves out the demo's places, exceptions and view check" do
    assert_equal [ {}, {}, nil ], [ KeystoneUi::Pages.places, KeystoneUi::Pages.access_exceptions, KeystoneUi::Pages.view_check_method ]
  end
end

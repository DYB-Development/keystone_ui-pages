# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::DemoAccessTest < ActiveSupport::TestCase
  test "the demo refuses a client portal page to an anonymous visitor" do
    page = KeystoneUi::Pages::Page.new(place: "client_portal")

    assert_not DemoAccess.allows?(page, "visitor")
  end
end

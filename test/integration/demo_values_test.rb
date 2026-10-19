# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::DemoValuesTest < ActiveSupport::TestCase
  test "the demo gives an anonymous visitor values that say they are not signed in and have not purchased" do
    assert_equal({ "signed_in" => "no", "purchased" => "no" }, DemoValues.for("visitor"))
  end

  test "the demo gives a signed-in client values with their name that say they have not purchased" do
    assert_equal({ "signed_in" => "yes", "purchased" => "no", "client_name" => "Acme" }, DemoValues.for("signed_in_client"))
  end
end

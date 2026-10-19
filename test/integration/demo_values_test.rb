# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::DemoValuesTest < ActiveSupport::TestCase
  test "the demo gives an anonymous visitor values that say they are not signed in and have not purchased" do
    assert_equal({ "signed_in" => "no", "purchased" => "no" }, DemoValues.for("visitor"))
  end
end

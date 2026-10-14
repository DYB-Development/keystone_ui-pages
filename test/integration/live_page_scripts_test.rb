# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::LivePageScriptsTest < ActionDispatch::IntegrationTest
  test "the live page loads no editor script" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").publish

    get "/pages/pricing"

    assert_select "script[src*='keystone_ui/pages']", 0
  end
end

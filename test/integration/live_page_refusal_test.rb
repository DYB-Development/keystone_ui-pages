# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::LivePageRefusalTest < ActionDispatch::IntegrationTest
  test "a page with no live version is not found when the host sets no refusal" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/pricing"

    assert_response :not_found
  end
end

# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::LivePageRefusalTest < ActionDispatch::IntegrationTest
  teardown { KeystoneUi::Pages.refusal_method = nil }

  test "a page with no live version is not found when the host sets no refusal" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/pricing"

    assert_response :not_found
  end

  test "a page with no live version gets the host's refusal" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/pricing"

    assert_equal [ 403, "This page is not available" ], [ response.status, response.body ]
  end
end

# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::LivePageRefusalTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.refusal_method = nil
    KeystoneUi::Pages.owner_method = nil
  end

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

  test "a page belonging to another owner gets the same refusal as a page that does not exist" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.owner_method = :current_team
    Team.create!(name: "Acme")
    other = Team.create!(name: "Globex")
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", owner: other).publish
    get "/pages/missing", headers: { "X-Team" => "Acme" }
    missing = [ response.status, response.body ]

    get "/pages/pricing", headers: { "X-Team" => "Acme" }

    assert_equal missing, [ response.status, response.body ]
  end
end

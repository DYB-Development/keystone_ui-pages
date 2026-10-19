# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::DemoVisitorTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.view_check_method = :may_view_demo_page?
    KeystoneUi::Pages::Page.create!(name: "Account", slug: "account", place: "client_portal").publish
  end

  teardown do
    KeystoneUi::Pages.view_check_method = nil
  end

  test "a developer acting as a signed-in client sees a client portal page" do
    get "/demo/visitor/signed_in_client"

    get "/pages/account"

    assert_response :ok
  end

  test "a developer switching back to an anonymous visitor is refused a client portal page" do
    get "/demo/visitor/signed_in_client"
    get "/demo/visitor/visitor"

    get "/pages/account"

    assert_response :not_found
  end
end

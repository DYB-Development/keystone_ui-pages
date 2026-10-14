# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::BuilderRefusalTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.edit_check_method = :may_edit_pages?
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
  end

  teardown do
    KeystoneUi::Pages.refusal_method = nil
    KeystoneUi::Pages.edit_check_method = nil
  end

  test "a person the edit check refuses gets the host's refusal on the builder" do
    get "/pages/manage/pages/#{@page.id}", headers: { "X-Editor" => "refused" }

    assert_equal [ 403, "This page is not available" ], [ response.status, response.body ]
  end
end

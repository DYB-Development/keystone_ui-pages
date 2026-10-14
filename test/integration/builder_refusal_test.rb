# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

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

  test "a person the edit check refuses gets the host's refusal when adding an element" do
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]

    post "/pages/manage/pages/#{@page.id}/elements", params: { key: "button", column_id: column_id }, headers: { "X-Editor" => "refused" }

    assert_equal [ 403, [] ], [ response.status, @page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"] ]
  end

  test "a person the edit check refuses gets the host's refusal when creating a page" do
    post "/pages/manage/pages", params: { page: { name: "About", slug: "about" } }, headers: { "X-Editor" => "refused" }

    assert_equal [ 403, false ], [ response.status, KeystoneUi::Pages::Page.exists?(slug: "about") ]
  end

  test "a person the edit check refuses gets the host's refusal when setting a field" do
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "button", column_id: column_id))
    element_id = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    patch "/pages/manage/pages/#{@page.id}/elements/#{element_id}", params: { field: "label", value: "Hi" }, headers: { "X-Editor" => "refused" }

    assert_equal [ 403, {} ], [ response.status, @page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] ]
  end

  test "a person the edit check refuses gets the host's refusal when publishing" do
    post "/pages/manage/pages/#{@page.id}/publish", headers: { "X-Editor" => "refused" }

    assert_equal [ 403, nil ], [ response.status, @page.reload.live_version ]
  end
end

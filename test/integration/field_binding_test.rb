# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FieldBindingTest < ActionDispatch::IntegrationTest
  setup { KeystoneUi::Pages::Values.names = { "client_name" => "Client name" } }
  teardown { KeystoneUi::Pages::Values.names = {} }

  test "binding a field through the builder's endpoint saves the value name and fallback" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id))
    element_id = page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    post "/pages/manage/pages/#{page.id}/elements/#{element_id}/bind", params: { field: "label", name: "client_name", fallback: "Our client" }, as: :json

    assert_equal({ "value" => "client_name", "fallback" => "Our client" }, page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"])
  end
end

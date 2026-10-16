# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::HostViewTest < ActionDispatch::IntegrationTest
  test "a host app's own view draws a published page with the values it hands in" do
    page = KeystoneUi::Pages::Page.create!(name: "Product", slug: "product")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)
    page.publish

    get "/products/product", params: { client: "Acme" }

    assert_select "[data-host-layout] .ks-button", text: "Acme"
  end
end

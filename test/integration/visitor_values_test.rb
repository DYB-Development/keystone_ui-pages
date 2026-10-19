# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::VisitorValuesTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.values_method = :visitor_page_values
    page = KeystoneUi::Pages::Page.create!(name: "Course", slug: "course")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    button = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]
    button["fields"]["label"] = "Open"
    button["show_when"] = { "value" => "owner", "equals" => "yes" }
    page.update!(document: document)
    page.publish
  end

  teardown do
    KeystoneUi::Pages.values_method = nil
  end

  test "a published page shows an element whose show-when matches the visitor's values" do
    get "/pages/course", headers: { "X-Owner" => "yes" }

    assert_select "[data-live-page] .ks-button", text: "Open"
  end

  test "a published page hides an element whose show-when does not match the visitor's values" do
    get "/pages/course", headers: { "X-Owner" => "no" }

    assert_select "[data-live-page] .ks-button", count: 0
  end

  test "a published page shows the visitor's value in a text setting bound to it" do
    page = KeystoneUi::Pages::Page.create!(name: "Welcome", slug: "welcome")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)
    page.publish

    get "/pages/welcome", headers: { "X-Client-Name" => "Acme" }

    assert_select "[data-live-page] .ks-button", text: "Acme"
  end

  test "a visitor is never shown the cached version drawn for another visitor" do
    cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    get "/pages/course", headers: { "X-Owner" => "yes" }

    get "/pages/course", headers: { "X-Owner" => "no" }

    assert_select "[data-live-page] .ks-button", count: 0
  ensure
    Rails.cache = cache
  end

  test "with no values method a published page is drawn with no values" do
    KeystoneUi::Pages.values_method = nil

    get "/pages/course", headers: { "X-Owner" => "yes" }

    assert_select "[data-live-page] .ks-button", count: 0
  end
end

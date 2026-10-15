# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::HostHelperTest < ActiveSupport::TestCase
  test "a host draws a published page from its own view with its own values" do
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)
    page.publish

    html = ApplicationController.new.view_context.keystone_ui_page(page, values: { client_name: "Acme" })

    assert_equal "Acme", Nokogiri::HTML(html).at_css(".ks-button").text.strip
  end

  test "a host page is drawn once per version and set of values" do
    cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)
    page.publish
    view = ApplicationController.new.view_context
    view.keystone_ui_page(page, values: { client_name: "Acme" })
    page.live_version.update_column(:document, KeystoneUi::Pages::Document.blank)

    labels = [ { client_name: "Acme" }, { client_name: "Globex" } ].map { |values| Nokogiri::HTML(view.keystone_ui_page(page.reload, values: values)).at_css(".ks-button")&.text&.strip }

    assert_equal [ "Acme", nil ], labels
  ensure
    Rails.cache = cache
  end
end

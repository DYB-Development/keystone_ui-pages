# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::HostHelperTest < ActiveSupport::TestCase
  teardown do
    KeystoneUi::Pages.places = nil
  end

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

  test "a host draws the published version it names after a later one is published" do
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = "First"
    page.update!(document: document)
    page.publish
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = "Second"
    page.update!(document: document)
    page.publish

    html = ApplicationController.new.view_context.keystone_ui_page(page, version: 1)

    assert_equal "First", Nokogiri::HTML(html).at_css(".ks-button").text.strip
  end

  test "a host draws the published version it names of an archived page" do
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = "First"
    page.update!(document: document)
    page.publish
    page.archive

    html = ApplicationController.new.view_context.keystone_ui_page(page, version: 1)

    assert_equal "First", Nokogiri::HTML(html).at_css(".ks-button").text.strip
  end

  test "a host draws the published version it names with its own values" do
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)
    page.publish
    page.publish

    html = ApplicationController.new.view_context.keystone_ui_page(page, version: 1, values: { client_name: "Acme" })

    assert_equal "Acme", Nokogiri::HTML(html).at_css(".ks-button").text.strip
  end

  test "a host draws nothing for an unpublished page when it names no version" do
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    page.publish
    page.unpublish

    html = ApplicationController.new.view_context.keystone_ui_page(page)

    assert_nil html
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

  test "a host drawing an older version of a page by number gives it no event address to send a view to" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary", place: "marketing")
    2.times { page.publish }

    html = view_with_request.keystone_ui_page(page, version: 1)

    assert_nil Nokogiri::HTML(html).at_css("[data-page-events]")
  end

  private

  def view_with_request
    ApplicationController.new.tap { |controller| controller.request = ActionDispatch::TestRequest.create }.view_context
  end
end

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
end

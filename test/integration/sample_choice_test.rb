# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::SampleChoiceTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme", "acme" ], [ "Globex", "globex" ] ] }
    KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "client_name" => choice.capitalize } }
  end

  teardown do
    KeystoneUi::Pages::Values.chooser = nil
    KeystoneUi::Pages::Values.provider = nil
  end

  test "choosing a sample redraws the builder's page with that sample's values" do
    page = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)

    post "/pages/manage/pages/#{page.id}/sample", params: { choice: "globex" }, as: :json

    assert_equal "Globex", Nokogiri::HTML(response.parsed_body["canvas"]).at_css(".ks-button").text.strip
  end
end

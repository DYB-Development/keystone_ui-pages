# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::EditorLiveViewTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme", "acme" ], [ "Globex", "globex" ] ] }
    KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "billing" => [ { "label" => "Client", "value" => choice.capitalize } ] } }
  end

  teardown do
    KeystoneUi::Pages::Values.chooser = nil
    KeystoneUi::Pages::Values.provider = nil
  end

  test "an editor opens a page's published version drawn with the sample values chosen in the builder" do
    page = KeystoneUi::Pages::Page.create!(name: "Report", slug: "report")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "value_list", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["rows"] = { "value" => "billing", "fallback" => nil }
    page.update!(document: document)
    page.publish
    post "/pages/manage/pages/#{page.id}/sample", params: { choice: "globex" }, as: :json

    get "/pages/manage/pages/#{page.id}/live"

    assert_equal "Globex", Nokogiri::HTML(response.body).at_css("[data-live-page] .ks-value-list-value")&.text&.strip
  end

  test "a page that uses no values from the app opens from the builder exactly as its public address shows it" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "stat_card", column_id: column_id))
    page.publish
    get "/pages/pricing"
    public_page = Nokogiri::HTML(response.body).at_css("[data-live-page]").to_html

    get "/pages/manage/pages/#{page.id}/live"

    assert_equal public_page, Nokogiri::HTML(response.body).at_css("[data-live-page]").to_html
  end
end

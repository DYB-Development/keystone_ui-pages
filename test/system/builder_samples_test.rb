# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::BuilderSamplesTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages::Values.names = { "client_name" => "Client name" }
    KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme", "acme" ], [ "Globex", "globex" ] ] }
    KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "client_name" => choice.capitalize } }
    @page_record = KeystoneUi::Pages::Page.create!(name: "Summary", slug: "summary")
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@page_record.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => "Our client" }
    @page_record.update!(document: document)
  end

  teardown do
    KeystoneUi::Pages::Values.names = {}
    KeystoneUi::Pages::Values.chooser = nil
    KeystoneUi::Pages::Values.provider = nil
  end

  test "the builder draws a bound field with the host's first sample" do
    visit "/pages/manage/pages/#{@page_record.id}"

    assert_selector "[data-element-id] .ks-button", text: "Acme"
  end

  test "an editor chooses which sample the builder draws bound fields with" do
    visit "/pages/manage/pages/#{@page_record.id}"

    select "Globex", from: "Preview with"

    assert_selector "[data-element-id] .ks-button", text: "Globex"
  end
end

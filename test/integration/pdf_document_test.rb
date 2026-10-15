# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/pdf_document"

class KeystoneUi::Pages::PdfDocumentTest < ActiveSupport::TestCase
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => "Our client" }
    @page.update!(document: document)
    @page.publish
  end

  test "a PDF document holds the published page drawn with the values given" do
    html = KeystoneUi::Pages::PdfDocument.html(@page.versions.live.first, values: { "client_name" => "Acme" })

    assert_includes html, ">Acme<"
  end
end

# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::HostElementPdfTest < ActiveSupport::TestCase
  QUOTE_DRAWING = ->(surface, fields) { surface.text(fields[:text], size: "--text-base") }

  setup { KeystoneUi::Pages.pdf_drawing = :ruby }

  teardown do
    KeystoneUi::Pages.pdf_drawing = nil
    KeystoneUi::Pages.catalog.leave_out(:quote)
  end

  test "a host element registered with a PDF drawing is drawn in the PDF by that drawing, with its fields filled from the host's values" do
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ], pdf: QUOTE_DRAWING)
    page = page_holding(:quote, "text" => { "value" => "client_name", "fallback" => "Client" })

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: { "client_name" => "Acme" }) }

    assert_includes texts(pdf.file.download), "Acme"
  end

  private

  def page_holding(key, fields)
    page = KeystoneUi::Pages::Page.create!(name: "Report", slug: "report")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, key.to_s, column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"].merge!(fields)
    page.update!(document: document)
    page.publish
    page
  end

  def texts(pdf)
    pdf.scan(/\[([^\]]*)\] TJ/).flatten.map { |kerned| kerned.scan(/<(\h+)>/).flatten.join.then { |text| [ text ].pack("H*") } }
  end
end

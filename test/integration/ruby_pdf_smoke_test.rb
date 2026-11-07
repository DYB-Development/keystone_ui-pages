# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::RubyPdfSmokeTest < ActiveSupport::TestCase
  setup { KeystoneUi::Pages.pdf_drawing = :ruby }
  teardown { KeystoneUi::Pages.pdf_drawing = nil }

  test "a host that chooses the Ruby drawing gets a published page as a PDF on a machine with no Chrome, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(KeystoneUi::Pages::Operations.add(page.document, "heading", column_id: column_id), "label", column_id: column_id))
    page.publish

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "%PDF", pdf.file.download[0, 4]
  end
end

# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PdfTest < ActiveSupport::TestCase
  test "a page version keeps a PDF file for the values it was drawn with" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish

    pdf = KeystoneUi::Pages::Pdf.create!(version: page.versions.live.first, values_digest: "abc", file: { io: StringIO.new("%PDF-1.4"), filename: "pricing.pdf" })

    assert_equal "%PDF-1.4", pdf.reload.file.download
  end
end

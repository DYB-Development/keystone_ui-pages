# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"

class KeystoneUi::Pages::PagePdfTest < ActiveSupport::TestCase
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    @page.publish
    @printed = 0
  end

  test "a host gets the published page as a PDF file" do
    pdf = printing { KeystoneUi::Pages.pdf(@page, values: { "client_name" => "Acme" }) }

    assert_equal "%PDF-printed", pdf.file.download
  end

  private

  def printing(&)
    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { @printed += 1; "%PDF-printed" }, &)
  end
end

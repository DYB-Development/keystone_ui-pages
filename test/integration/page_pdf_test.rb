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

  test "asking again for the same values returns the kept PDF without printing it again" do
    printing { 2.times { KeystoneUi::Pages.pdf(@page, values: { "client_name" => "Acme" }) } }

    assert_equal 1, @printed
  end

  test "different values make a new PDF rather than returning the kept one" do
    printing do
      KeystoneUi::Pages.pdf(@page, values: { "client_name" => "Acme" })
      KeystoneUi::Pages.pdf(@page, values: { "client_name" => "Globex" })
    end

    assert_equal 2, @printed
  end

  test "a newly published version makes a new PDF rather than returning the old one" do
    printing do
      KeystoneUi::Pages.pdf(@page, values: {})
      @page.publish
      KeystoneUi::Pages.pdf(@page.reload, values: {})
    end

    assert_equal 2, @printed
  end

  private

  def printing(&)
    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { @printed += 1; "%PDF-printed" }, &)
  end
end

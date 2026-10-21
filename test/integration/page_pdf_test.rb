# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PagePdfTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

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

  test "a host can have the PDF made ahead of time so a later download is already made" do
    printing { perform_enqueued_jobs { KeystoneUi::Pages.prepare_pdf(@page, values: { "client_name" => "Acme" }) } }

    assert_equal 1, KeystoneUi::Pages::Pdf.count
  end

  test "a host gets the PDF of the published version it names after a later one is published" do
    labelled("First")
    labelled("Second")
    printed = nil

    KeystoneUi::Pages::Printer.stub(:pdf, ->(html) { printed = html; "%PDF-printed" }) { KeystoneUi::Pages.pdf(@page, version: 2) }

    assert_equal "First", Nokogiri::HTML(printed).at_css(".ks-button").text.strip
  end

  private

  def labelled(label)
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"].empty? ? KeystoneUi::Pages::Operations.add(@page.document, "button", column_id: column_id) : @page.document
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = label
    @page.update!(document: document)
    @page.publish
  end

  def printing(&)
    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { @printed += 1; "%PDF-printed" }, &)
  end
end

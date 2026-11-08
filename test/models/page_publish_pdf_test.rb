# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/printer"

class KeystoneUi::Pages::PagePublishPdfTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "publishing a page that uses no host values has its PDF made" do
    page = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")

    assert_enqueued_with(job: KeystoneUi::Pages::PdfJob) { page.publish }
  end

  test "publishing a page that uses host values leaves its PDFs to the host, which has the values" do
    page = KeystoneUi::Pages::Page.create!(name: "Report", slug: "report")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = { "value" => "client_name", "fallback" => nil }
    page.update!(document: document)

    assert_no_enqueued_jobs(only: KeystoneUi::Pages::PdfJob) { page.publish }
  end

  test "publishing a page whose PDF is refused still publishes it" do
    page = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")

    refusing { perform_enqueued_jobs { page.publish } }

    assert_equal 1, page.versions.live.count
  end

  test "a refused PDF made on publishing is reported through the host's error reporting with the page named" do
    page = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")
    reports = []
    subscriber = Object.new.tap { |listener| listener.define_singleton_method(:report) { |error, context:, **| reports << [ error.message, context ] } }
    Rails.error.subscribe(subscriber)

    refusing { perform_enqueued_jobs { page.publish } }

    assert_equal [ [ "No font", { page_id: page.id, page_name: "Home" } ] ], reports.map { |message, context| [ message, context.slice(:page_id, :page_name) ] }
  ensure
    Rails.error.unsubscribe(subscriber)
  end

  private

  def refusing(&publishing)
    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { raise KeystoneUi::Pages::PrintFailed, "No font" }, &publishing)
  end
end

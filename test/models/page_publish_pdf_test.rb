# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

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
end

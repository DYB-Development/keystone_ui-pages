# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PagePublishPdfTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "publishing a page that uses no host values has its PDF made" do
    page = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")

    assert_enqueued_with(job: KeystoneUi::Pages::PdfJob) { page.publish }
  end
end

# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/submission"

class KeystoneUi::Pages::DemoSubmissionsTest < ActiveSupport::TestCase
  test "the demo writes each submission's page, form name and values to the server log" do
    logged = StringIO.new
    logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(logged)
    page = KeystoneUi::Pages::Page.new(slug: "contact")

    DemoSubmissions.record(KeystoneUi::Pages::Submission.new(page: page, version: nil, form_name: "Contact", element_id: "abc", values: { "name" => "Ada" }, request: nil, bot: false))

    assert_includes logged.string, %(Form submission on contact: Contact {"name":"Ada"})
  ensure
    Rails.logger = logger
  end
end

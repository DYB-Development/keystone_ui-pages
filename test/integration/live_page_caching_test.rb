# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::LivePageCachingTest < ActionDispatch::IntegrationTest
  setup do
    @cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "button", column_id: column_id))
    @page.publish
  end

  teardown { Rails.cache = @cache }

  test "a live page's HTML is drawn once per version and later requests get the cached HTML" do
    get "/pages/pricing"
    first = response.body
    @page.live_version.update_column(:document, KeystoneUi::Pages::Document.blank)

    get "/pages/pricing"

    assert_equal first, response.body
  end
end

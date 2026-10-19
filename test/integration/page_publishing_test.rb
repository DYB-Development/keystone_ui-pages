# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PagePublishingTest < ActionDispatch::IntegrationTest
  setup do
    @cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    @page.publish
  end

  teardown { Rails.cache = @cache }

  test "a visitor cannot see a page after an editor unpublishes it, even once it was cached" do
    get "/pages/pricing"

    post "/pages/manage/pages/#{@page.id}/unpublish"
    get "/pages/pricing"

    assert_response :not_found
  end

  test "a visitor cannot see a page after an editor archives it, even once it was cached" do
    get "/pages/pricing"

    post "/pages/manage/pages/#{@page.id}/archive"
    get "/pages/pricing"

    assert_response :not_found
  end
end

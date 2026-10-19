# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PagePublishingTest < ActionDispatch::IntegrationTest
  setup do
    @cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    @page.publish
  end

  teardown do
    Rails.cache = @cache
    KeystoneUi::Pages.refusal_method = nil
  end

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

  test "a visitor refused because a page is unpublished gets the host's refusal" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    @page.unpublish

    get "/pages/pricing"

    assert_equal [ 403, "This page is not available" ], [ response.status, response.body ]
  end
end

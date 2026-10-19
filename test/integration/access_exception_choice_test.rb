# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::AccessExceptionChoiceTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.access_exceptions = { "public_preview" => "Public preview" }
  end

  teardown do
    KeystoneUi::Pages.access_exceptions = nil
  end

  test "an editor gives a page an access exception from the builder" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    post "/pages/manage/pages/#{page.id}/access_exception", params: { access_exception: "public_preview" }, as: :json

    assert_equal "public_preview", page.reload.access_exception
  end

  test "an editor clears a page's access exception from the builder" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", access_exception: "public_preview")

    post "/pages/manage/pages/#{page.id}/access_exception", params: { access_exception: "" }, as: :json

    assert_nil page.reload.access_exception
  end

  test "the builder is refused an access exception the host does not name" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    post "/pages/manage/pages/#{page.id}/access_exception", params: { access_exception: "everyone" }, as: :json

    assert_response :unprocessable_entity
  end
end

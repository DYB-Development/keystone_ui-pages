# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::ArchivedPagesTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    KeystoneUi::Pages::Page.create!(name: "Old offer", slug: "old-offer").archive
  end

  test "the page list leaves out archived pages" do
    get "/pages/manage/pages"

    assert_equal [ "pricing" ], Nokogiri::HTML(response.body).css("[data-page]").map { |row| row["data-page"] }
  end
end

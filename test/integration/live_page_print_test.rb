# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::LivePagePrintTest < ActionDispatch::IntegrationTest
  setup { KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").publish }

  test "a printed live page has a white background" do
    get "/pages/pricing"

    assert_select "[data-live-page].print\\:bg-white", 1
  end

  test "a printed live page keeps the colours of its charts and shaded cells" do
    get "/pages/pricing"

    assert_select "[data-live-page].print\\:\\[print-color-adjust\\:exact\\]", 1
  end
end

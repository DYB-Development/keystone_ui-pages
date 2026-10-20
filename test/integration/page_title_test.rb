# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PageTitleTest < ActionDispatch::IntegrationTest
  test "a visitor sees a page's published title in the browser tab" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.update!(document: KeystoneUi::Pages::Operations.title(page.document, "Plans and prices"))
    page.publish

    get "/pages/pricing"

    assert_select "title", text: "Plans and prices"
  end
end

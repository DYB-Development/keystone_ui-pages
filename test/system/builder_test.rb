# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "an editor creates a page with a name and a slug and opens it in the builder" do
    visit "/pages/manage/pages/new"
    fill_in "page[name]", with: "Pricing"
    fill_in "page[slug]", with: "pricing"
    click_on "Create"

    assert_selector "[data-page-builder] h1", text: "Pricing"
  end

  test "the builder lists the elements the catalog offers" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-element-palette] [data-element-key='button']", text: "Button"
  end
end

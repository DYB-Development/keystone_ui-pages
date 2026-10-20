# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderTitleTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "an editor sets the page's title in the builder" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    fill_in "Page title", with: "Plans and prices"
    find("[data-settings-panel] p.ks-hint", text: "Select something on the page").click
    find_button("↶ Undo", disabled: false)
    visit "/pages/manage/pages/#{page_record.id}"

    assert_field "Page title", with: "Plans and prices"
  end
end

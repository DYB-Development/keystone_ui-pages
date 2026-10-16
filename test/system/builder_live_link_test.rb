# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderLiveLinkTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "the builder's top bar opens the published version of the page being edited" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page_record.publish
    visit "/pages/manage/pages/#{page_record.id}"

    within("[data-builder-top-bar]") { click_on "View live" }

    assert_current_path "/pages/manage/pages/#{page_record.id}/live"
  end
end

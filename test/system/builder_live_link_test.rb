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

  test "the builder's top bar has no link to a published version when the page has never been published" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_equal [ true, false ], [ has_link?("History"), has_link?("View live", wait: 0) ]
  end
end

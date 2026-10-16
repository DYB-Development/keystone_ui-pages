# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderBackLinkTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "the builder's top bar goes back to the address the host app named" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}?return_to=#{CGI.escape("/pages/manage/pages/#{page_record.id}/versions")}"

    within("[data-builder-top-bar]") { click_on "Back" }

    assert_current_path "/pages/manage/pages/#{page_record.id}/versions"
  end

  test "an editor goes back from the builder at phone width" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.current_window.resize_to(390, 844)
    visit "/pages/manage/pages/#{page_record.id}"

    within("[data-builder-top-bar]") { click_on "Back" }

    assert_current_path "/pages/manage/pages"
  ensure
    page.current_window.resize_to(1400, 1000)
  end
end

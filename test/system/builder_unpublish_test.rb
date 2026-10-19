# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderUnpublishTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "an editor unpublishes a published page from the builder" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page_record.publish
    visit "/pages/manage/pages/#{page_record.id}"

    click_on "Unpublish"
    page.document.synchronize { raise Capybara::ExpectationNotMet unless page_record.reload.state == :unpublished }

    assert_equal :unpublished, page_record.state
  end
end

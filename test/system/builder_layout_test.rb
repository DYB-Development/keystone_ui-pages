# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::BuilderLayoutTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "sections, rows and columns in the builder have the same classes as on the live page" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page_record.publish
    visit "/pages/manage/pages/#{page_record.id}"
    built = layout_classes

    visit "/pages/pricing"

    assert_equal built, layout_classes
  end

  test "an editor adds a section to the page" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    click_on "Add section"

    assert_selector "[data-page-canvas] [data-section-id]", count: 2, visible: :all
  end

  private

  def layout_classes
    assert_selector ".ks-pages-column", visible: :all
    all(".ks-pages-section, .ks-pages-row, .ks-pages-column", visible: :all).map { |node| node[:class] }
  end
end

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

  test "an editor adds a column to a row" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-column-id]").click
    click_on "Add column"

    assert_selector "[data-row-id] [data-column-id]", count: 2
  end

  test "an editor adds a row to a section" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-column-id]").click
    click_on "Add row"

    assert_selector "[data-section-id] [data-row-id]", count: 2, visible: :all
  end

  test "an editor sets a column's width for wide and narrow screens" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-column-id]").click

    select "1/2", from: "Width on wide screens"
    assert_selector "[data-column-id].sm\\:col-span-6"
    select "1/3", from: "Width on narrow screens"

    assert_selector "[data-column-id].col-span-4.sm\\:col-span-6"
  end

  private

  def layout_classes
    assert_selector ".ks-pages-column", visible: :all
    all(".ks-pages-section, .ks-pages-row, .ks-pages-column", visible: :all).map { |node| node[:class] }
  end
end

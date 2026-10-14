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
    assert_selector "[data-column-id].\\@sm\\:col-span-6"
    select "1/3", from: "Width on narrow screens"

    assert_selector "[data-column-id].col-span-4.\\@sm\\:col-span-6"
  end

  test "an editor sets a row's gap from keystone_ui's spacing sizes" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-column-id]").click

    click_on "Select row"
    select "lg", from: "Row gap"

    assert_selector "[data-row-id].ks-grid-gap-lg"
  end

  test "an editor sets a section's spacing from keystone_ui's spacing sizes" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-column-id]").click
    click_on "Select row"

    click_on "Select section"
    select "lg", from: "Section spacing"

    assert_selector "[data-section-id].ks-section-lg"
  end

  test "an editor sets a column's vertical alignment" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-column-id]").click

    select "bottom", from: "Vertical alignment"

    assert_selector "[data-column-id].justify-end"
  end

  test "an editor sets an element's horizontal alignment" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id))
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-element-id] .ks-button").click

    select "center", from: "Horizontal alignment"

    assert_selector "[data-element-id].justify-center"
  end

  test "removing a section that still holds elements is refused in the builder, saying how many" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id)
    page_record.update!(document: KeystoneUi::Pages::Operations.add_column(document, row_id: row_id))
    visit "/pages/manage/pages/#{page_record.id}"
    all("[data-column-id]").last.click
    click_on "Select row"
    click_on "Select section"

    click_on "Remove section"

    assert_selector "[data-layout-refusal]", text: "This section holds 1 element, so it cannot be removed"
  end

  test "column widths that add up to more than their row are refused in the builder, naming the row" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add_column(page_record.document, row_id: row_id))
    visit "/pages/manage/pages/#{page_record.id}"
    all("[data-column-id]").first.click
    select "2/3", from: "Width on wide screens"
    assert_selector "[data-column-id].\\@sm\\:col-span-8"
    all("[data-column-id]").last.click

    select "1/2", from: "Width on wide screens"

    assert_selector "[data-layout-refusal]", text: "Row 1 of section 1 is wider than the page on wide screens"
  end

  test "an editor removes the selected element from the builder" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id))
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-element-id] .ks-button").click

    click_on "Remove element"

    assert_no_selector "[data-element-id]"
  end

  private

  def layout_classes
    assert_selector ".ks-pages-column", visible: :all
    all(".ks-pages-section, .ks-pages-row, .ks-pages-column", visible: :all).map { |node| node[:class] }
  end
end

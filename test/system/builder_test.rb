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

  test "an editor drags an element from the palette into the page's column with a mouse" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))

    assert_selector "[data-column-id] [data-element-id] .ks-button"
  end

  private

  def dragged(source, target)
    page.driver.browser.action
      .click_and_hold(source.native).move_by(10, 10).pause(duration: 0.1)
      .move_to(target.native).pause(duration: 0.1).move_by(2, 2).pause(duration: 0.1)
      .release.perform
  end
end

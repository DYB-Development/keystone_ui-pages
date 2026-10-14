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

  test "an editor drags an element from the palette into the page's column with the keyboard" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    palette_item = find("[data-element-palette] [data-element-key='button']")

    palette_item.send_keys(:space)
    40.times { palette_item.send_keys(:arrow_right) }
    5.times { palette_item.send_keys(:arrow_down) }
    palette_item.send_keys(:space)

    assert_selector "[data-column-id] [data-element-id] .ks-button"
  end

  test "an editor drags an element from the palette into the page's column with a finger" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    touched(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))

    assert_selector "[data-column-id] [data-element-id] .ks-button"
  end

  test "a dropped element is drawn by the same component with the same classes as on the live page" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    built = find("[data-column-id] [data-element-id] .ks-button")[:outerHTML]
    page_record.reload.publish

    visit "/pages/pricing"

    assert_equal built, find(".ks-pages-column .ks-button")[:outerHTML]
  end

  test "selecting an element shows its fields" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))

    find("[data-element-id] .ks-button").click

    assert_equal [ "Label", "Address" ], all("[data-element-fields] label").map(&:text)
  end

  test "changing a field redraws the element once the field loses focus" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    find("[data-element-id] .ks-button").click

    fill_in "Label", with: "Get a quote"
    find("[data-element-fields] label", text: "Address").click

    assert_selector "[data-element-id] .ks-button", text: "Get a quote"
  end

  test "the builder draws the page inside the host's editor layout" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-editor-layout] [data-page-canvas] [data-column-id]"
  end

  private

  def touched(source, target)
    actions = page.driver.browser.action
    finger = actions.add_pointer_input(:touch, "finger")
    actions
      .move_to(source.native, device: "finger").pointer_down(:left, device: "finger").pause(device: finger, duration: 0.3)
      .move_by(10, 10, device: "finger").pause(device: finger, duration: 0.1)
      .move_to(target.native, device: "finger").pause(device: finger, duration: 0.1)
      .pointer_up(:left, device: "finger").perform
  end

  def dragged(source, target)
    page.driver.browser.action
      .click_and_hold(source.native).move_by(10, 10).pause(duration: 0.1)
      .move_to(target.native).pause(duration: 0.1).move_by(2, 2).pause(duration: 0.1)
      .release.perform
  end
end

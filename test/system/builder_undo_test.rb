# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::BuilderUndoTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "an editor undoes adding an element and redoes it from the builder's top bar" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    assert_selector "[data-element-id] .ks-button"

    within("[data-builder-top-bar]") { click_on "↶ Undo" }
    assert_no_selector "[data-element-id] .ks-button"
    within("[data-builder-top-bar]") { click_on "↷ Redo" }

    assert_selector "[data-element-id] .ks-button"
  end

  test "the Undo button is greyed out with a hint when there is nothing to undo" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-builder-top-bar] button[disabled][title='Nothing to undo']", text: "↶ Undo"
  end

  test "the Redo button is greyed out with a hint when there is nothing to redo" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-builder-top-bar] button[disabled][title='Nothing to redo']", text: "↷ Redo"
  end

  test "an editor undoes an edit after reloading the builder" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    assert_selector "[data-element-id] .ks-button"

    visit "/pages/manage/pages/#{page_record.id}"
    within("[data-builder-top-bar]") { click_on "↶ Undo" }

    assert_no_selector "[data-element-id] .ks-button"
  end

  test "an editor presses Undo and Redo at phone width" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page_record.edit(KeystoneUi::Pages::Operations.add(page_record.document, "button", column_id: column_id))
    page.current_window.resize_to(390, 844)
    visit "/pages/manage/pages/#{page_record.id}"

    within("[data-builder-top-bar]") { click_on "↶ Undo" }
    within("[data-builder-top-bar]") { click_on "↷ Redo" }

    assert_selector "[data-element-id] .ks-button"
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  private

  def dragged(source, target)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", source)
    page.driver.browser.action
      .click_and_hold(source.native).move_by(10, 10).pause(duration: 0.1)
      .move_to(target.native).pause(duration: 0.1).move_by(2, 2).pause(duration: 0.1)
      .release.perform
  end
end

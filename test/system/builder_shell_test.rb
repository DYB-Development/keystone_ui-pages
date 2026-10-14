# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderShellTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "the builder fills the window with a top bar, an element panel, the page and a settings panel" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-builder-top-bar]"
    assert_equal [ true, true, true, true ], page.evaluate_script(<<~JS)
      (() => {
        const shell = document.querySelector("[data-builder]").getBoundingClientRect()
        const panel = document.querySelector("[data-element-palette]").getBoundingClientRect()
        const frame = document.querySelector("[data-page-frame]").getBoundingClientRect()
        const settings = document.querySelector("[data-settings-panel]").getBoundingClientRect()
        return [shell.height === window.innerHeight && shell.width === window.innerWidth, panel.right <= frame.left, frame.right <= settings.left, settings.right === window.innerWidth]
      })()
    JS
  end

  test "the page is drawn as a page on a contrasting background" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-page-canvas]", visible: :all
    assert_equal [ true, true ], page.evaluate_script(<<~JS)
      (() => {
        const canvas = getComputedStyle(document.querySelector("[data-page-canvas]"))
        const frame = getComputedStyle(document.querySelector("[data-page-frame]"))
        return [canvas.backgroundColor !== frame.backgroundColor && canvas.backgroundColor !== "rgba(0, 0, 0, 0)", canvas.boxShadow !== "none"]
      })()
    JS
  end
end

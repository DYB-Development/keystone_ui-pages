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
end

# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

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

  test "the top bar shows the page's name, a choice of phone, tablet and desktop width, and the Publish button" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_equal [ "Pricing", %w[Phone Tablet Desktop], "Publish" ], [
      find("[data-builder-top-bar] h1").text,
      all("[data-builder-top-bar] [data-device-width] button").map(&:text),
      find("[data-builder-top-bar] button[type='submit']").text
    ]
  end

  test "choosing phone draws the page at phone width" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    click_on "Phone"

    assert_equal 390, page.evaluate_script("Math.round(document.querySelector('[data-page-canvas]').getBoundingClientRect().width)")
  end

  test "at phone width the page's columns stack the way they do on a phone" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add_column(page_record.document, row_id: row_id))
    visit "/pages/manage/pages/#{page_record.id}"

    click_on "Phone"

    assert_equal true, page.evaluate_script(<<~JS)
      (() => {
        const [first, second] = [...document.querySelectorAll("[data-column-id]")].map((column) => column.getBoundingClientRect())
        return second.top >= first.bottom
      })()
    JS
  end
end

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
        const canvas = getComputedStyle(document.querySelector("[data-page-sheet]"))
        const frame = getComputedStyle(document.querySelector("[data-page-frame]"))
        return [canvas.backgroundColor !== frame.backgroundColor && canvas.backgroundColor !== "rgba(0, 0, 0, 0)", canvas.boxShadow !== "none"]
      })()
    JS
  end

  test "the page is drawn on the page colour the host app's theme sets" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    assert_selector "[data-page-canvas]", visible: :all

    color = page.evaluate_script(<<~JS)
      (() => {
        const look = document.createElement("style")
        look.textContent = ":root { --ks-color-page: rgb(1, 2, 3); }"
        document.head.append(look)
        return getComputedStyle(document.querySelector("[data-page-canvas]")).backgroundColor
      })()
    JS

    assert_equal "rgb(1, 2, 3)", color
  end

  test "the top bar offers light, dark and system modes and opens on the editor's own mode" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    page.driver.browser.manage.add_cookie(name: "keystone_theme", value: "dark")
    visit "/pages/manage/pages/#{page_record.id}"

    mode = find("[data-builder-top-bar] [data-theme-mode]")

    assert_equal [ %w[Light Dark System], "dark" ], [ mode.all("option").map(&:text), mode.value ]
  end

  test "choosing dark mode in the top bar draws the page in the dark mode" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-builder-top-bar] [data-theme-mode]").select("Dark")

    assert_equal "dark", page.evaluate_script("document.documentElement.dataset.theme")
  end

  test "choosing system mode in the top bar lets the page follow the device" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-builder-top-bar] [data-theme-mode]").select("System")

    assert_nil page.evaluate_script("document.documentElement.getAttribute('data-theme')")
  end

  test "an editor in custom mode is offered custom mode, chosen, beside the other modes" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    page.driver.browser.manage.add_cookie(name: "keystone_theme", value: "custom")
    visit "/pages/manage/pages/#{page_record.id}"

    mode = find("[data-builder-top-bar] [data-theme-mode]")

    assert_equal [ %w[Light Dark System Custom], "custom" ], [ mode.all("option").map(&:text), mode.value ]
  end

  test "the top bar offers the looks the host app registers and opens on the editor's own look" do
    KeystoneUi.configuration.register_look :plain, "plain.css"
    KeystoneUi.configuration.register_look :bold, "bold.css"
    KeystoneUi.configuration.default_look = :bold
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    look = find("[data-builder-top-bar] [data-look-choice]")

    assert_equal [ %w[Plain Bold], "bold" ], [ look.all("option").map(&:text), look.value ]
  ensure
    KeystoneUi.configuration.looks.clear
    KeystoneUi.configuration.default_look = nil
  end

  test "choosing a look in the top bar draws the page in that look" do
    KeystoneUi.configuration.register_look :plain, "plain.css"
    KeystoneUi.configuration.register_look :bold, "bold.css"
    KeystoneUi.configuration.default_look = :plain
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-builder-top-bar] [data-look-choice]").select("Bold")

    assert_equal "bold", page.evaluate_script("document.documentElement.dataset.look")
  ensure
    KeystoneUi.configuration.looks.clear
    KeystoneUi.configuration.default_look = nil
  end

  test "in dark mode the builder draws its own top bar and element buttons dark" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-builder-top-bar] [data-theme-mode]").select("Dark")

    backgrounds = page.evaluate_script(<<~JS)
      ["[data-builder]", "[data-element-palette] [data-element-key]"].map((selector) => getComputedStyle(document.querySelector(selector)).backgroundColor)
    JS
    assert_equal [], backgrounds.select { |color| color == "rgb(255, 255, 255)" }
  end

  test "in dark mode the builder draws its top bar and width choice borders in the theme's dark border colour" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-builder-top-bar] [data-theme-mode]").select("Dark")

    borders = page.evaluate_script(<<~JS)
      (() => {
        const probe = document.createElement("div")
        probe.style.color = "var(--ks-color-border-dark)"
        document.body.append(probe)
        const dark = getComputedStyle(probe).color
        return [getComputedStyle(document.querySelector("[data-builder-top-bar]")).borderBottomColor, getComputedStyle(document.querySelector("[data-device-width]")).borderTopColor].map((color) => color === dark)
      })()
    JS

    assert_equal [ true, true ], borders
  end

  test "choosing print draws the page at paper width in light mode, as it prints" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    find("[data-builder-top-bar] [data-theme-mode]").select("Dark")

    within("[data-device-width]") { click_on "Print" }

    assert_equal [ "794px", "light", "rgb(255, 255, 255)" ], page.evaluate_script(<<~JS)
      (() => {
        const sheet = document.querySelector("[data-page-sheet]")
        return [sheet.style.width, sheet.dataset.theme, getComputedStyle(sheet).backgroundColor]
      })()
    JS
  end

  test "the top bar shows the page's name, a choice of phone, tablet and desktop width, and the Publish button" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_equal [ "Pricing", %w[Phone Tablet Desktop Print], "Publish" ], [
      find("[data-builder-top-bar] h1").text,
      all("[data-builder-top-bar] [data-device-width] button").map(&:text),
      find("[data-builder-top-bar] button[type='submit']").text
    ]
  end

  test "choosing phone draws the page at phone width" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    click_on "Phone"

    assert_equal 390, page.evaluate_script("Math.round(document.querySelector('[data-page-sheet]').getBoundingClientRect().width)")
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

  test "an empty column shows a drop area saying an element can be dropped there" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-column-id]"
    assert_equal [ '"Drop an element here"', "dashed" ], page.evaluate_script(<<~JS)
      (() => {
        const column = document.querySelector("[data-column-id]")
        return [getComputedStyle(column, "::after").content, getComputedStyle(column).borderTopStyle]
      })()
    JS
  end

  test "hovering a column outlines it, and not its row, and shows that it is a column" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-column-id]").hover

    assert_equal [ "solid", '"Column"', "none" ], page.evaluate_script(<<~JS)
      (() => {
        const column = document.querySelector("[data-column-id]")
        const row = document.querySelector("[data-row-id]")
        return [getComputedStyle(column).outlineStyle, getComputedStyle(column, "::before").content, getComputedStyle(row).outlineStyle]
      })()
    JS
  end

  test "the selected column stays outlined and shows a toolbar with move, duplicate and remove" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    find("[data-column-id]").click
    find("[data-builder-top-bar] h1").hover

    assert_equal [ %w[Move Duplicate Remove], "solid" ], [
      all("[data-selection-toolbar] button").map(&:text),
      page.evaluate_script("getComputedStyle(document.querySelector('[data-column-id]')).outlineStyle")
    ]
  end

  test "the element panel shows each element with an icon and its name" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    hero = find("[data-element-palette] [data-element-key='hero']")
    button = find("[data-element-palette] [data-element-key='button']")
    assert_equal [ "Hero", true ], [ hero.text.strip, hero.find("svg path")[:d] != button.find("svg path")[:d] ]
  end

  test "the element panel groups similar elements together" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    data = find("[data-element-palette] [data-element-group='Data']")
    assert_equal [ "data", %w[progress stat_card figure data_table value_list bar_chart line_chart] ], [ data.find("h2").text.downcase, data.all("[data-element-key]").map { |item| item["data-element-key"] } ]
  end

  test "a search box in the element panel filters the list of elements" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    fill_in "Search elements", with: "car"

    assert_equal %w[card], all("[data-element-palette] [data-element-key]").map { |item| item["data-element-key"] }
  end

  test "on a phone-width screen the element panel opens over the page" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.current_window.resize_to(390, 844)
    visit "/pages/manage/pages/#{page_record.id}"
    assert_no_selector "[data-element-palette]"

    click_on "Elements"

    assert_equal [ true, true ], page.evaluate_script(<<~JS)
      (() => {
        const panel = document.querySelector("[data-element-palette]").getBoundingClientRect()
        const frame = document.querySelector("[data-page-frame]").getBoundingClientRect()
        return [panel.left < frame.right && panel.right > frame.left, frame.width >= window.innerWidth - 1]
      })()
    JS
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  test "the builder's top bar opens the page's history of published versions" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page_record.publish
    visit "/pages/manage/pages/#{page_record.id}"

    within("[data-builder-top-bar]") { click_on "History" }

    assert_selector "[data-version='1']"
  end
end

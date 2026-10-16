# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

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

    across, down = page.evaluate_script(<<~JS)
      (() => {
        const from = document.querySelector("[data-element-palette] [data-element-key='button']").getBoundingClientRect()
        const to = document.querySelector("[data-column-id]").getBoundingClientRect()
        return [Math.round((to.left + to.width / 2 - from.left - from.width / 2) / 10), Math.round((to.top + to.height / 2 - from.top - from.height / 2) / 10)]
      })()
    JS

    palette_item.send_keys(:space)
    across.abs.times { palette_item.send_keys(across.positive? ? :arrow_right : :arrow_left) }
    down.abs.times { palette_item.send_keys(down.positive? ? :arrow_down : :arrow_up) }
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

    assert_equal [ "Label", "Address", "Horizontal alignment" ], all("[data-element-fields] label").map(&:text)
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

  test "the builder draws elements in the host's accent colour" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    find("[data-builder-top-bar] h1").hover

    assert_equal color_of_variable("--ks-color-accent"), background_of("[data-element-id] .ks-button")
  end

  test "the builder follows the host's dark theme when the host chooses it" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    find("[data-element-id] .ks-button").click

    page.execute_script(%(document.documentElement.dataset.theme = "dark"))

    assert_equal color_of_variable("--ks-color-border-control-dark"), page.evaluate_script("getComputedStyle(document.querySelector('[data-element-fields] .ks-input')).borderTopColor")
  end

  test "publishing from the builder makes the current draft the page's live version" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"
    dragged(find("[data-element-palette] [data-element-key='button']"), find("[data-column-id]"))
    find("[data-element-id] .ks-button").click
    fill_in "Label", with: "Get a quote"
    find("[data-element-fields] label", text: "Address").click
    assert_selector "[data-element-id] .ks-button", text: "Get a quote"

    page.execute_script("document.body.dataset.beforePublish = ''")
    click_on "Publish"
    reloaded = "!('beforePublish' in document.body.dataset) && document.querySelector('[data-builder-top-bar] a[href$=\"/live\"]') !== null"
    page.document.synchronize { raise Capybara::ExpectationNotMet unless page.evaluate_script(reloaded) }
    visit "/pages/pricing"

    assert_selector "[data-live-page] .ks-pages-column .ks-button", text: "Get a quote"
  end

  test "the builder offers an element the host draws with its own component next to keystone_ui's" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    visit "/pages/manage/pages/#{page_record.id}"

    dragged(find("[data-element-palette] [data-element-key='testimonial']"), find("[data-column-id]"))

    assert_selector "[data-column-id] [data-element-id] blockquote.testimonial", text: "It works."
  end

  test "the builder does not offer a keystone_ui element the host leaves out" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    visit "/pages/manage/pages/#{page_record.id}"

    assert_selector "[data-element-palette] [data-element-key='button']"
    assert_no_selector "[data-element-palette] [data-element-key='copy_button']"
  end

  test "an editor drags an element into another column with a mouse" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    document = KeystoneUi::Pages::Operations.add_column(page_record.document, row_id: row_id)
    first = document["sections"][0]["rows"][0]["columns"][0]["id"]
    second = document["sections"][0]["rows"][0]["columns"][1]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(document, "button", column_id: first))
    visit "/pages/manage/pages/#{page_record.id}"

    dragged(find("[data-element-id] .ks-button"), find("[data-column-id='#{second}']"))

    assert_selector "[data-column-id='#{second}'] [data-element-id] .ks-button"
  end

  test "the builder marks where a dragged element will land before it is dropped" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    document = KeystoneUi::Pages::Operations.add_column(page_record.document, row_id: row_id)
    first = document["sections"][0]["rows"][0]["columns"][0]["id"]
    second = document["sections"][0]["rows"][0]["columns"][1]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(document, "button", column_id: first))
    visit "/pages/manage/pages/#{page_record.id}"

    page.driver.browser.action.click_and_hold(find("[data-element-id] .ks-button").native).move_by(10, 10).pause(duration: 0.1)
      .move_to(find("[data-column-id='#{second}']").native).pause(duration: 0.2).perform

    assert_selector "[data-column-id='#{second}'][data-drop-target]"
  end

  test "an editor drags an element into another column with the keyboard" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    document = KeystoneUi::Pages::Operations.add_column(page_record.document, row_id: row_id)
    first = document["sections"][0]["rows"][0]["columns"][0]["id"]
    second = document["sections"][0]["rows"][0]["columns"][1]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(document, "button", column_id: first))
    visit "/pages/manage/pages/#{page_record.id}"
    placed = find("[data-element-id]")

    placed.send_keys(:space)
    60.times { placed.send_keys(:arrow_right) }
    placed.send_keys(:space)

    assert_selector "[data-column-id='#{second}'] [data-element-id] .ks-button"
  end

  test "an editor drags an element into another column with a finger" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page_record.document["sections"][0]["rows"][0]["id"]
    document = KeystoneUi::Pages::Operations.add_column(page_record.document, row_id: row_id)
    first = document["sections"][0]["rows"][0]["columns"][0]["id"]
    second = document["sections"][0]["rows"][0]["columns"][1]["id"]
    page_record.update!(document: KeystoneUi::Pages::Operations.add(document, "button", column_id: first))
    visit "/pages/manage/pages/#{page_record.id}"

    touched(find("[data-element-id] .ks-button"), find("[data-column-id='#{second}']"))

    assert_selector "[data-column-id='#{second}'] [data-element-id] .ks-button"
  end

  private

  def background_of(selector)
    find(selector)
    page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).backgroundColor")
  end

  def color_of_variable(name)
    page.evaluate_script(<<~JS)
      (() => {
        const probe = document.createElement("div")
        probe.style.backgroundColor = "var(#{name})"
        document.body.appendChild(probe)
        const color = getComputedStyle(probe).backgroundColor
        probe.remove()
        return color
      })()
    JS
  end

  def dragged(source, target)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", source)
    page.driver.browser.action
      .click_and_hold(source.native).move_by(10, 10).pause(duration: 0.1)
      .move_to(target.native).pause(duration: 0.1).move_by(2, 2).pause(duration: 0.1)
      .release.perform
  end
end

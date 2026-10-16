# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::LivePageTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@page_record.document, "button", column_id: column_id)
    element_id = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page_record.update!(document: KeystoneUi::Pages::Operations.set(added, element_id: element_id, field: "label", value: "Get a quote"))
    @page_record.publish
  end

  test "a page's address shows its live version drawn with keystone_ui components inside the host's layout" do
    visit "/pages/pricing"

    assert_selector "[data-host-layout] .ks-button", text: "Get a quote"
  end

  test "a live page draws its button in the host's accent colour" do
    visit "/pages/pricing"

    assert_equal color_of_variable("--ks-color-accent"), page.evaluate_script("getComputedStyle(document.querySelector('.ks-button')).backgroundColor")
  end

  test "the sample app draws a live page at desktop width at a limited width, centred with space on both sides" do
    visit "/pages/pricing"

    assert_equal [ true, true ], page.evaluate_script(<<~JS)
      (() => {
        const box = document.querySelector("[data-live-page]").getBoundingClientRect()
        const right = document.documentElement.clientWidth - box.right
        return [box.left > 0, Math.abs(box.left - right) <= 1]
      })()
    JS
  end

  test "the sample app draws a live page at phone width with space on both sides" do
    page.current_window.resize_to(390, 844)
    visit "/pages/pricing"

    assert_equal [ true, true ], page.evaluate_script(<<~JS)
      (() => {
        const box = document.querySelector("[data-live-page]").getBoundingClientRect()
        return [box.left >= 16, document.documentElement.clientWidth - box.right >= 16]
      })()
    JS
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  private

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

  test "a live page opens in the mode its visitor chose in the host app" do
    visit "/pages/pricing"
    page.driver.browser.manage.add_cookie(name: "keystone_theme", value: "dark")
    visit "/pages/pricing"

    assert_equal "dark", page.evaluate_script("document.documentElement.dataset.theme")
  end

  test "a live page opens in the look the host app gives its visitor" do
    KeystoneUi.configuration.register_look :plain, "plain.css"
    KeystoneUi.configuration.register_look :bold, "bold.css"
    KeystoneUi.configuration.default_look = :bold

    visit "/pages/pricing"

    assert_equal "bold", page.evaluate_script("document.documentElement.dataset.look")
  ensure
    KeystoneUi.configuration.looks.clear
    KeystoneUi.configuration.default_look = nil
  end

  test "a live page in dark mode tells the browser it is dark, so its default background turns dark behind light text" do
    visit "/pages/pricing"
    page.driver.browser.manage.add_cookie(name: "keystone_theme", value: "dark")
    visit "/pages/pricing"

    assert_equal "dark", page.evaluate_script("getComputedStyle(document.documentElement).colorScheme")
  end
end

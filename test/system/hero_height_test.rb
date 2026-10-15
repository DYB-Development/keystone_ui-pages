# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::HeroHeightTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @page_record = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @document = KeystoneUi::Pages::Operations.add(@page_record.document, "hero", column_id: column_id)
  end

  test "a hero set to content height is only as tall as its content in the builder" do
    @document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["height"] = "content"
    @page_record.update!(document: @document)

    visit "/pages/manage/pages/#{@page_record.id}"

    assert_equal true, page.evaluate_script(<<~JS)
      (() => {
        const hero = document.querySelector("[data-element-id] .ks-hero")
        return getComputedStyle(hero).minHeight === "0px" && hero.getBoundingClientRect().height < window.innerHeight
      })()
    JS
  end

  test "an editor chooses a hero's height from a short list in the settings panel" do
    @page_record.update!(document: @document)
    visit "/pages/manage/pages/#{@page_record.id}"
    find("[data-element-id] .ks-hero h1").click

    select "content", from: "Height"

    assert_equal [ %w[content tall full_screen], true ], [ all("#ks-pages-field-height option").map(&:value), has_css?("[data-element-id][class~='[&_.ks-hero]:min-h-0']") ]
  end

  test "a new hero starts at a height that leaves room for the page below it" do
    @page_record.update!(document: @document)

    visit "/pages/manage/pages/#{@page_record.id}"

    assert_equal true, page.evaluate_script(<<~JS)
      (() => {
        const hero = document.querySelector("[data-element-id] .ks-hero")
        return hero.getBoundingClientRect().height <= window.innerHeight * 0.6
      })()
    JS
  end

  test "the builder shows a hero at the same height as the live page at phone and desktop width" do
    @page_record.update!(document: @document)
    @page_record.publish
    hero_height = -> { page.evaluate_script("Math.round(document.querySelector('.ks-hero').getBoundingClientRect().height)") }

    visit "/pages/manage/pages/#{@page_record.id}"
    desktop_builder = hero_height.call
    click_on "Phone"
    phone_builder = hero_height.call
    visit "/pages/home"
    desktop_live = hero_height.call
    page.current_window.resize_to(390, 844)
    visit "/pages/home"
    phone_live = hero_height.call

    assert_equal [ desktop_live, phone_live ], [ desktop_builder, phone_builder ]
  ensure
    page.current_window.resize_to(1400, 1000)
  end
end

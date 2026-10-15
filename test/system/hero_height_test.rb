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
end

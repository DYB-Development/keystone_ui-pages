# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::PrerenderedPageBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a page the browser prerenders sends its view only when the visitor opens it" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event.kind })
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish

    visit "/pages/pricing?prerendering=1"
    while_prerendering = wait_for { received.dup.presence }.to_a
    page.execute_script(<<~JS)
      Object.defineProperty(document, "prerendering", { value: false, configurable: true })
      document.dispatchEvent(new Event("prerenderingchange"))
    JS

    assert_equal [ [], [ "view" ] ], [ while_prerendering, wait_for { received.dup.presence } ]
  end
end

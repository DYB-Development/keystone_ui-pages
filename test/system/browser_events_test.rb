# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BrowserEventsBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    @page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "opening a reporting page fires a view event on the document carrying the page's slug and place" do
    @page_record.publish

    visit "/pages/pricing"

    assert_equal [ { "name" => "keystone-ui-pages:view", "slug" => "pricing", "place" => "marketing" } ], wait_for { page_events.presence }
  end

  private

  def page_events
    page.evaluate_script("window.pageEvents")
  end
end

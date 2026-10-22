# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

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

  test "clicking a link inside an element fires a click event carrying the page's slug, place, element id and the link's address" do
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@page_record.document, "button", column_id: column_id)
    button_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    document = KeystoneUi::Pages::Operations.set(document, element_id: button_id, field: "label", value: "Get a quote")
    @page_record.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: button_id, field: "href", value: "#quote"))
    @page_record.publish

    visit "/pages/pricing"
    click_on "Get a quote"

    assert_equal [ { "name" => "keystone-ui-pages:click", "slug" => "pricing", "place" => "marketing", "element" => button_id, "href" => "#{page.evaluate_script("location.origin")}/pages/pricing#quote" } ],
      wait_for { page_events.select { |event| event["name"].end_with?("click") }.presence }
  end

  test "the view event fires even when the event address fails" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { raise "handler failed" })
    @page_record.publish
    Capybara.raise_server_errors = false

    visit "/pages/pricing"

    assert_equal [ "keystone-ui-pages:view" ], wait_for { page_events.map { |event| event["name"] }.presence }
  ensure
    Capybara.reset_sessions!
    Capybara.raise_server_errors = true
  end

  test "a page from a place with no handler fires no browser event" do
    KeystoneUi::Pages.register_place("help", label: "Help centre")
    KeystoneUi::Pages::Page.create!(name: "Returns", slug: "returns", place: "help").publish

    visit "/pages/returns"

    assert_empty page_events
  end

  private

  def page_events
    page.evaluate_script("window.pageEvents")
  end
end

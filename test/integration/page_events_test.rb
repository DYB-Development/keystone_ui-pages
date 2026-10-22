# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageEventsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a place registered with an event handler is reported and one registered without it is not" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) {})
    KeystoneUi::Pages.register_place("client_report", label: "Client report")

    assert_equal [ true, false ], [ KeystoneUi::Pages.reported?("marketing"), KeystoneUi::Pages.reported?("client_report") ]
  end

  test "a view for a live page in a place with a handler calls the handler once with the page, place, kind and request" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event })
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").tap(&:publish)

    post "/pages/pricing/events"

    assert_equal [ [ page, "marketing", "view", "/pages/pricing/events" ] ], received.map { |event| [ event.page, event.place, event.kind, event.request.path ] }
  end
end

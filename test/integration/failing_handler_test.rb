# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::FailingHandlerTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { raise "handler failed" })
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").tap(&:publish)
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a handler that raises is reported through the host's error reporting with the page and the kind of event" do
    reports = []
    subscriber = Object.new.tap { |listener| listener.define_singleton_method(:report) { |error, context:, **| reports << [ error.message, context ] } }
    Rails.error.subscribe(subscriber)

    post "/pages/pricing/events", params: { kind: "click", element: "abc" }

    assert_equal [ [ "handler failed", { page_id: @page.id, kind: "click" } ] ], reports.map { |message, context| [ message, context.slice(:page_id, :kind) ] }
  ensure
    Rails.error.unsubscribe(subscriber)
  end
end

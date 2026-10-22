# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FailingHandlerTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { raise "handler failed" })
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "button", column_id: column_id))
    @button_id = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a handler that raises is reported through the host's error reporting with the page and the kind of event" do
    reports = []
    subscriber = Object.new.tap { |listener| listener.define_singleton_method(:report) { |error, context:, **| reports << [ error.message, context ] } }
    Rails.error.subscribe(subscriber)

    post "/pages/pricing/events", params: { kind: "click", element: @button_id }

    assert_equal [ [ "handler failed", { page_id: @page.id, kind: "click" } ] ], reports.map { |message, context| [ message, context.slice(:page_id, :kind) ] }
  ensure
    Rails.error.unsubscribe(subscriber)
  end

  test "a handler that raises gets the browser the same answer as one that succeeds" do
    post "/pages/pricing/events"

    assert_response :no_content
  end
end

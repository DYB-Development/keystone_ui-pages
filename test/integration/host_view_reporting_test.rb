# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::HostViewReportingTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a host view drawing a page from a place with no handler loads no reporting script and gives no event address" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) { })
    KeystoneUi::Pages.register_place("client_report", label: "Client report", slug: false)
    KeystoneUi::Pages::Page.create!(name: "Monthly report", slug: "monthly-report", place: "client_report").publish

    get "/products/monthly-report"

    assert_select "script[src*='keystone_ui_pages/reporting'], [data-page-events]", 0
  end

  test "a request for the host view from a client that runs no script calls no handler" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event })
    KeystoneUi::Pages::Page.create!(name: "Product", slug: "product", place: "marketing").publish

    get "/products/product"

    assert_empty received
  end
end

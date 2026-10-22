# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageEventsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.view_check_method = nil
    KeystoneUi::Pages.refusal_method = nil
    KeystoneUi::Pages.owner_method = nil
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

  test "a view for a page whose place has no handler calls no handler and is refused" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event })
    KeystoneUi::Pages.register_place("client_report", label: "Client report")
    KeystoneUi::Pages::Page.create!(name: "Monthly report", slug: "monthly-report", place: "client_report").publish

    post "/pages/monthly-report/events"

    assert_equal [ 404, 0 ], [ response.status, received.size ]
  end

  test "a view for a page with no live version, including an archived page, calls no handler and is refused" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event })
    KeystoneUi::Pages::Page.create!(name: "Draft", slug: "draft", place: "marketing")
    KeystoneUi::Pages::Page.create!(name: "Old", slug: "old", place: "marketing").tap(&:publish).archive

    statuses = %w[draft old].map do |slug|
      post "/pages/#{slug}/events"
      response.status
    end

    assert_equal [ 404, 404, 0 ], statuses + [ received.size ]
  end

  test "a view for a page the host's view check refuses calls no handler and gets the host's refusal" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event })
    KeystoneUi::Pages.view_check_method = :may_view_page?
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish

    post "/pages/pricing/events", headers: { "X-Visitor" => "blocked" }

    assert_equal [ 403, 0 ], [ response.status, received.size ]
  end

  test "a view for another owner's page calls no handler" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event })
    KeystoneUi::Pages.owner_method = :current_team
    Team.create!(name: "Acme")
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing", owner: Team.create!(name: "Globex")).publish

    post "/pages/pricing/events", headers: { "X-Team" => "Acme" }

    assert_equal [ 404, 0 ], [ response.status, received.size ]
  end

  test "a view sent without a form token is accepted while the host checks form tokens" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) {})
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish
    ActionController::Base.allow_forgery_protection = true

    post "/pages/pricing/events"

    assert_response :no_content
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "accepting a view adds no row to any of the gem's tables" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(_event) {})
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish
    connection = ActiveRecord::Base.connection
    rows = -> { connection.tables.grep(/\Akeystone_ui_pages_/).sum { |table| connection.select_value("SELECT COUNT(*) FROM #{table}").to_i } }
    before = rows.call

    post "/pages/pricing/events"

    assert_equal before, rows.call
  end
end

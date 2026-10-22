# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageViewCountsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.view_check_method = nil
    KeystoneUi::Pages.refusal_method = nil
    KeystoneUi::Pages.owner_method = nil
  end

  test "a place registered with counting on is counted and one registered without it is not" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    KeystoneUi::Pages.register_place("client_report", label: "Client report")

    assert_equal [ true, false ], [ KeystoneUi::Pages.counted?("marketing"), KeystoneUi::Pages.counted?("client_report") ]
  end

  test "sending a view for a published page in a counted place adds one to its view total for today" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").tap(&:publish)

    post "/pages/pricing/views"

    assert_equal 1, page.counts.find_by(day: Date.current, kind: "view")&.total
  end

  test "a view for a page in an uncounted place or in no place is refused and adds nothing" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report")
    KeystoneUi::Pages::Page.create!(name: "Monthly report", slug: "monthly-report", place: "client_report").publish
    KeystoneUi::Pages::Page.create!(name: "About", slug: "about").publish

    statuses = %w[monthly-report about].map do |slug|
      post "/pages/#{slug}/views"
      response.status
    end

    assert_equal [ 404, 404, 0 ], statuses + [ KeystoneUi::Pages::PageCount.count ]
  end

  test "a view for a counted page with no live version, including an archived page, is refused and adds nothing" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    KeystoneUi::Pages::Page.create!(name: "Draft", slug: "draft", place: "marketing")
    KeystoneUi::Pages::Page.create!(name: "Old", slug: "old", place: "marketing").tap(&:publish).archive

    statuses = %w[draft old].map do |slug|
      post "/pages/#{slug}/views"
      response.status
    end

    assert_equal [ 404, 404, 0 ], statuses + [ KeystoneUi::Pages::PageCount.count ]
  end

  test "a view for a page the host's view check refuses gets the host's refusal and adds nothing" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    KeystoneUi::Pages.view_check_method = :may_view_page?
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish

    post "/pages/pricing/views", headers: { "X-Visitor" => "blocked" }

    assert_equal [ 403, 0 ], [ response.status, KeystoneUi::Pages::PageCount.count ]
  end

  test "a view for another owner's page is refused and adds nothing" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    KeystoneUi::Pages.owner_method = :current_team
    Team.create!(name: "Acme")
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing", owner: Team.create!(name: "Globex")).publish

    post "/pages/pricing/views", headers: { "X-Team" => "Acme" }

    assert_equal [ 404, 0 ], [ response.status, KeystoneUi::Pages::PageCount.count ]
  end

  test "a view sent without a form token is accepted while the host checks form tokens" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", counts: true)
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing").publish
    ActionController::Base.allow_forgery_protection = true

    post "/pages/pricing/views"

    assert_response :no_content
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end

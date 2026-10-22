# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageViewCountsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
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
end

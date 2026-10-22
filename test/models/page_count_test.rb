# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageCountTest < ActiveSupport::TestCase
  test "a view arriving after another request created today's total adds to that total" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.counts.create!(day: Date.current, kind: "view", total: 1)

    KeystoneUi::Pages::PageCount.add(page, "view")

    assert_equal 2, page.counts.find_by(day: Date.current, kind: "view").total
  end

  test "archiving a page keeps its view totals and restoring it still has them" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing").tap(&:publish)
    KeystoneUi::Pages::PageCount.add(page, "view")

    page.archive
    page.restore

    assert_equal 1, page.counts.find_by(day: Date.current, kind: "view")&.total
  end
end

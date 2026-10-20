# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PageTest < ActiveSupport::TestCase
  test "publishing a page makes the next numbered version, holding a copy of the draft, the live one" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    page.publish

    assert_equal [ [ 1, page.document, "live" ] ], page.versions.map { |version| [ version.number, version.document, version.status ] }
  end

  test "publishing again marks the previous live version superseded" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish

    page.publish

    assert_equal %w[superseded live], page.versions.reload.map(&:status)
  end

  test "a page cannot hold a second live version" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish

    assert_raises(ActiveRecord::RecordNotUnique) do
      page.versions.create!(number: 2, document: page.document, status: :live)
    end
  end

  test "a page cannot take a slug another page of the same owner already uses" do
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    page = KeystoneUi::Pages::Page.new(name: "Plans", slug: "pricing")

    assert_equal [ "has already been taken" ], page.tap(&:validate).errors[:slug]
  end

  test "a published version gives the page's title to a host" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.update!(document: KeystoneUi::Pages::Operations.title(page.document, "Plans and prices"))

    page.publish

    assert_equal "Plans and prices", page.live_version.title
  end

  test "a title changed after publishing stays off the live version until the page is published again" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.update!(document: KeystoneUi::Pages::Operations.title(page.document, "Plans"))
    page.publish

    page.edit(KeystoneUi::Pages::Operations.title(page.document, "New plans"))
    before = page.live_version.title
    page.publish

    assert_equal [ "Plans", "New plans" ], [ before, page.reload.live_version.title ]
  end
end

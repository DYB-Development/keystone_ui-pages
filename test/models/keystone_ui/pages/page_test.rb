# frozen_string_literal: true

require "test_helper"

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
end

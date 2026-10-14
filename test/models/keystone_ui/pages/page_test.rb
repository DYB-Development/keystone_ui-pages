# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageTest < ActiveSupport::TestCase
  test "publishing a page makes the next numbered version, holding a copy of the draft, the live one" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    page.publish

    assert_equal [ [ 1, page.document, "live" ] ], page.versions.map { |version| [ version.number, version.document, version.status ] }
  end
end

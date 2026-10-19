# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageStateTest < ActiveSupport::TestCase
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
  end

  test "a page never published is a draft" do
    assert_equal :draft, @page.state
  end
end

# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageStateTest < ActiveSupport::TestCase
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
  end

  test "a page never published is a draft" do
    assert_equal :draft, @page.state
  end

  test "publishing makes a page published" do
    @page.publish

    assert_equal :published, @page.state
  end

  test "unpublishing a published page makes it unpublished" do
    @page.publish

    @page.unpublish

    assert_equal :unpublished, @page.state
  end

  test "unpublishing keeps the page's earlier versions" do
    @page.publish
    @page.publish

    @page.unpublish

    assert_equal 2, @page.versions.count
  end

  test "an unpublished page can be published again" do
    @page.publish
    @page.unpublish

    @page.publish

    assert_equal :published, @page.state
  end

  test "archiving a page makes it archived" do
    @page.archive

    assert_equal :archived, @page.state
  end
end

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

  test "archiving a published page takes its live version down" do
    @page.publish

    @page.archive

    assert_nil @page.live_version
  end

  test "restoring an archived page that was never published makes it a draft" do
    @page.archive

    @page.restore

    assert_equal :draft, @page.state
  end

  test "restoring an archived page that was published makes it unpublished, not published" do
    @page.publish
    @page.archive

    @page.restore

    assert_equal :unpublished, @page.state
  end

  test "an archived page cannot be published" do
    @page.archive

    @page.publish

    assert_nil @page.live_version
  end
end

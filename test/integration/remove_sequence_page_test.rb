# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::RemoveSequencePageTest < ActionDispatch::IntegrationTest
  setup do
    ApplicationController.funnel_removals = []
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, removes_page_method: :remove_funnel_page)
    @landing = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
  end

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.refusal_method = nil
  end

  test "removing a page calls the host's remove page method with the sequence's key and the page" do
    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}"

    assert_equal [ [ "spring-sale", @landing ] ], ApplicationController.funnel_removals
  end

  test "a removed page is no longer served to visitors" do
    @landing.publish
    get "/pages/landing"

    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}"
    get "/pages/landing"

    assert_response :not_found
  end

  test "removing a page outside the sequence gets the host's refusal and archives nothing" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    other = KeystoneUi::Pages::Page.create!(name: "Other", slug: "other", place: "funnel", sequence_key: "autumn-sale")

    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{other.id}"

    assert_equal [ 403, nil ], [ response.status, other.reload.archived_at ]
  end

  test "removing a page in a place that names no remove page method gets the host's refusal and archives nothing" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)

    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}"

    assert_equal [ 403, nil ], [ response.status, @landing.reload.archived_at ]
  end

  test "after a page is removed the builder opens the page before it" do
    thanks = KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")

    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{thanks.id}"

    assert_redirected_to "/pages/manage/sequences/funnel/spring-sale?page_id=#{@landing.id}"
  end

  test "after a sequence's first page is removed the builder opens the sequence without naming a page" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")

    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}"

    assert_redirected_to "/pages/manage/sequences/funnel/spring-sale"
  end

  test "after the only page is removed the builder shows the empty page area" do
    delete "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}"
    follow_redirect!

    assert_nil builder_props["document"]
  end

  test "a page stays unarchived when the host's remove page method raises" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, removes_page_method: :fail_to_remove_funnel_page)

    begin
      delete "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}"
    rescue RuntimeError
      nil
    end

    assert_nil @landing.reload.archived_at
  end

  test "the confirmation screen names the page being removed" do
    get "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}/remove"

    assert_select ".ks-page-header-subtitle", text: "Landing"
  end

  test "the confirmation screen's Remove button sends the removal" do
    get "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}/remove"

    assert_select "form[action='/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}'] input[name='_method'][value='delete']"
  end

  test "the confirmation screen's Cancel link returns to the page on the sequence screen" do
    get "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}/remove"

    assert_select "a[href='/pages/manage/sequences/funnel/spring-sale?page_id=#{@landing.id}']", text: "Cancel"
  end

  test "the confirmation screen refuses a page outside the sequence" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    other = KeystoneUi::Pages::Page.create!(name: "Other", slug: "other", place: "funnel", sequence_key: "autumn-sale")

    get "/pages/manage/sequences/funnel/spring-sale/pages/#{other.id}/remove"

    assert_response :forbidden
  end

  test "each page in the sequence's list carries the address of its confirmation screen" do
    get "/pages/manage/sequences/funnel/spring-sale"

    assert_equal "/pages/manage/sequences/funnel/spring-sale/pages/#{@landing.id}/remove", builder_props.dig("sequence", "pages", 0, "remove_url")
  end

  private

  def builder_props
    JSON.parse(css_select("[data-react-ui='keystone_ui_pages/editor']").first["data-props"])
  end
end

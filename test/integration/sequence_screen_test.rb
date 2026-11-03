# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::SequenceScreenTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence)
  end

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.refusal_method = nil
  end

  test "opening a sequence the host answers nothing for gets the host's refusal" do
    get "/pages/manage/sequences/funnel/spring-sale", headers: { "X-Sequence" => "refused" }

    assert_equal [ 403, "This page is not available" ], [ response.status, response.body ]
  end

  test "the sequence screen gives the address that publishes the sequence when the place names a publish sequence method" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, publishes_sequence_method: :publish_funnel)

    get "/pages/manage/sequences/funnel/spring-sale"

    assert_equal "/pages/manage/sequences/funnel/spring-sale/publish", sequence_props["publish_url"]
  end

  test "the sequence screen gives no address for publishing when the place names no publish sequence method" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)

    get "/pages/manage/sequences/funnel/spring-sale"

    assert_nil sequence_props["publish_url"]
  end

  test "the publish address on the sequence screen names the page being built" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, publishes_sequence_method: :publish_funnel)
    landing = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    get "/pages/manage/sequences/funnel/spring-sale", params: { page_id: landing.id }

    assert_equal "/pages/manage/sequences/funnel/spring-sale/publish?page_id=#{landing.id}", sequence_props["publish_url"]
  end

  private

  def sequence_props
    JSON.parse(css_select("[data-react-ui='keystone_ui_pages/editor']").first["data-props"])["sequence"]
  end
end

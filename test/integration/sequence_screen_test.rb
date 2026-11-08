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

  test "each page in the sequence screen's list gives its state as a draft, published or unpublished page" do
    draft = KeystoneUi::Pages::Page.create!(name: "A draft", slug: "a-draft", place: "funnel", sequence_key: "spring-sale")
    published = KeystoneUi::Pages::Page.create!(name: "B published", slug: "b-published", place: "funnel", sequence_key: "spring-sale")
    published.publish
    unpublished = KeystoneUi::Pages::Page.create!(name: "C unpublished", slug: "c-unpublished", place: "funnel", sequence_key: "spring-sale")
    unpublished.publish
    unpublished.unpublish

    get "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "Draft", "Published", "Unpublished" ], sequence_props["pages"].map { |entry| entry["state"] }
  end

  test "the sequence screen gives the address of the host's own screen when the host's sequence names one" do
    get "/pages/manage/sequences/funnel/spring-sale", headers: { "X-Sequence-Screen" => "/funnels/spring-sale/flow" }

    assert_equal "/funnels/spring-sale/flow", sequence_props["screen_url"]
  end

  test "the sequence screen gives the label of the entry the host's sequence shows after its last page" do
    get "/pages/manage/sequences/funnel/spring-sale", headers: { "X-Sequence-End" => "End" }

    assert_equal "End", sequence_props["end_label"]
  end

  private

  def sequence_props
    JSON.parse(css_select("[data-react-ui='keystone_ui_pages/editor']").first["data-props"])["sequence"]
  end
end

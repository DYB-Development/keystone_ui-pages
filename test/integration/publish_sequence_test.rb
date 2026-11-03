# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PublishSequenceTest < ActionDispatch::IntegrationTest
  setup do
    ApplicationController.funnel_publishes = []
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, publishes_sequence_method: :publish_funnel)
  end

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.refusal_method = nil
  end

  test "pressing Publish calls the host's publish sequence method with the sequence's key" do
    post "/pages/manage/sequences/funnel/spring-sale/publish"

    assert_equal [ "spring-sale" ], ApplicationController.funnel_publishes
  end

  test "publishing a sequence the host answers nothing for gets the host's refusal and publishes nothing" do
    KeystoneUi::Pages.refusal_method = :refuse_page

    post "/pages/manage/sequences/funnel/spring-sale/publish", headers: { "X-Sequence" => "refused" }

    assert_equal [ 403, [] ], [ response.status, ApplicationController.funnel_publishes ]
  end

  test "publishing in a place that names no publish sequence method gets the host's refusal" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)

    post "/pages/manage/sequences/funnel/spring-sale/publish"

    assert_response :forbidden
  end

  test "after Publish the staff member is back on the sequence screen on the page that was open" do
    post "/pages/manage/sequences/funnel/spring-sale/publish", params: { page_id: 5 }

    assert_redirected_to "/pages/manage/sequences/funnel/spring-sale?page_id=5"
  end

  test "after Publish the sequence screen says the sequence was published" do
    post "/pages/manage/sequences/funnel/spring-sale/publish"
    follow_redirect!

    assert_equal "Spring sale funnel is published.", sequence_props["notice"]
  end

  test "when the host refuses to publish the sequence screen gives the host's reason" do
    post "/pages/manage/sequences/funnel/spring-sale/publish", headers: { "X-Publish" => "The last page has no content" }
    follow_redirect!

    assert_equal "The last page has no content", sequence_props["refusal"]
  end

  private

  def sequence_props
    JSON.parse(css_select("[data-react-ui='keystone_ui_pages/editor']").first["data-props"])["sequence"]
  end
end

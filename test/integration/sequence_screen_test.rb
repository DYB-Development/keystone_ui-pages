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
end

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
end

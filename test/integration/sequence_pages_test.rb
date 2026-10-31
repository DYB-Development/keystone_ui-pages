# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::SequencePagesTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)
  end

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.owner_method = nil
  end

  test "a page added to a sequence is in the sequence's place, belongs to the current owner and carries the sequence's key" do
    KeystoneUi::Pages.owner_method = :current_team
    team = Team.create!(name: "Acme")

    post "/pages/manage/sequences/funnel/spring-sale/pages", params: { page: { name: "Landing" } }, headers: { "X-Team" => "Acme" }

    page = KeystoneUi::Pages::Page.find_by(name: "Landing")
    assert_equal [ "funnel", team, "spring-sale" ], [ page.place, page.owner, page.sequence_key ]
  end
end

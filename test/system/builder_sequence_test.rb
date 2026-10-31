# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderSequenceTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence)
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "opening a sequence with pages shows its first page in the builder and its title and numbered pages beside it" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "Landing", "Spring sale funnel", [ "1 Landing", "2 Thanks" ] ],
      [ find("[data-builder-top-bar] h1").text, find("[data-sequence-pages] h2").text, all("[data-sequence-page]").map { |entry| entry.text.squish } ]
  end
end

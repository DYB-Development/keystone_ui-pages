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

  test "the page being built is marked in the sequence's list" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "1 Landing" ], all("[data-sequence-page][aria-current='page']").map { |entry| entry.text.squish }
  end

  test "choosing another page in the sequence's list opens it in the builder with the same list beside it" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-pages]") { click_on "Thanks" }

    assert_equal [ "Thanks", [ "1 Landing", "2 Thanks" ], [ "2 Thanks" ] ],
      [ find("[data-builder-top-bar] h1", text: "Thanks").text, all("[data-sequence-page]").map { |entry| entry.text.squish }, all("[data-sequence-page][aria-current='page']").map { |entry| entry.text.squish } ]
  end

  test "the builder's Back link on a sequence goes to the back address the host answered" do
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal "/funnels/spring-sale", URI(find("[data-builder-top-bar] a", text: "Back")[:href]).path
  end

  test "opening a sequence with no pages shows its title and an empty page area that says no page has been added yet" do
    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "Spring sale funnel", "No page has been added yet." ], [ find("[data-sequence-pages] h2").text, find("[data-page-frame]").text ]
  end

  test "publishing a page from the sequence screen brings staff back to the sequence screen on that page" do
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    thanks = KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    visit "/pages/manage/sequences/funnel/spring-sale?page_id=#{thanks.id}"

    within("[data-builder-top-bar]") { click_on "Publish" }

    assert_current_path "/pages/manage/sequences/funnel/spring-sale?page_id=#{thanks.id}"
  end
end

# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderSequenceTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "the sequence's list shows a Publish button when the place names a publish sequence method" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, publishes_sequence_method: :publish_funnel)

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_selector "[data-sequence-pages] button", text: "Publish"
  end

  test "the sequence's list shows no Publish button when the place names no publish sequence method" do
    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_selector "[data-sequence-pages]"
    assert_no_selector "[data-sequence-pages] button", text: "Publish"
  end

  test "pressing Publish in the sequence's list comes back to the screen saying the sequence is published" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, publishes_sequence_method: :publish_funnel)
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-pages]") { click_on "Publish" }

    assert_selector "[data-sequence-pages] [role='alert']", text: "Spring sale funnel is published."
  end

  test "the sequence's list shows the reason the host gave for refusing to publish" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, publishes_sequence_method: :refuse_to_publish_funnel)
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-pages]") { click_on "Publish" }

    assert_selector "[data-sequence-pages] [role='alert']", text: "The last page has no content"
  end

  test "opening a sequence with pages shows its first page in the builder and its title and numbered pages beside it" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "Landing", "Spring sale funnel", [ "1 Landing Draft", "2 Thanks Draft" ] ],
      [ find("[data-builder-top-bar] h1").text, find("[data-sequence-pages] h2").text, all("[data-sequence-page]").map { |entry| entry.text.squish } ]
  end

  test "each page in the sequence's list shows its state" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale").publish

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "Published", "Draft" ], all("[data-sequence-page] [data-page-state]").map(&:text)
  end

  test "the sequence's list links to the host's own screen when the host's sequence names one" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence_with_screen, adds_page_method: :add_funnel_page)

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal "/funnels/spring-sale/flow", URI(find("[data-sequence-pages] a", text: "Flow")[:href]).path
  end

  test "the sequence's list shows the host's entry after its last page" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence_with_end, adds_page_method: :add_funnel_page)
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "1 Landing Draft", "End" ], all("[data-sequence-pages] ol > li").map { |entry| entry.text.squish }
  end

  test "the sequence's list holds only its pages when the host's sequence names no entry after them" do
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal 1, all("[data-sequence-pages] ol > li", visible: :all).size
  end

  test "the page being built is marked in the sequence's list" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    visit "/pages/manage/sequences/funnel/spring-sale"

    assert_equal [ "1 Landing Draft" ], all("[data-sequence-page][aria-current='page']").map { |entry| entry.text.squish }
  end

  test "choosing another page in the sequence's list opens it in the builder with the same list beside it" do
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-pages]") { click_on "Thanks" }

    assert_equal [ "Thanks", [ "1 Landing Draft", "2 Thanks Draft" ], [ "2 Thanks Draft" ] ],
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

  test "unpublishing a page from the sequence screen brings staff back to the sequence screen on that page" do
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    thanks = KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    thanks.publish
    visit "/pages/manage/sequences/funnel/spring-sale?page_id=#{thanks.id}"

    within("[data-builder-top-bar]") { click_on "Unpublish" }

    assert_current_path "/pages/manage/sequences/funnel/spring-sale?page_id=#{thanks.id}"
  end

  test "going back to the builder from a page's history opened on the sequence screen brings staff back to the sequence screen on that page" do
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    thanks = KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    visit "/pages/manage/sequences/funnel/spring-sale?page_id=#{thanks.id}"
    within("[data-builder-top-bar]") { click_on "History" }

    click_on "Back to builder"

    assert_current_path "/pages/manage/sequences/funnel/spring-sale?page_id=#{thanks.id}"
  end

  test "adding a page from the sequence's list opens it in the builder with the list showing the sequence as the host now answers it" do
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-pages]") { click_on "Add page" }
    fill_in "page[name]", with: "Thanks"
    click_on "Create"

    assert_equal [ "Thanks", [ "1 Landing Draft", "2 Thanks Draft" ], [ "2 Thanks Draft" ] ],
      [ find("[data-builder-top-bar] h1", text: "Thanks").text, all("[data-sequence-page]").map { |entry| entry.text.squish }, all("[data-sequence-page][aria-current='page']").map { |entry| entry.text.squish } ]
  end

  test "adding a page with no name from an empty sequence gives it the place's default name and tells the host no page was open" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, default_name: "Step", sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)
    ApplicationController.funnel_additions = []
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-pages]") { click_on "Add page" }
    click_on "Create"
    find("[data-builder-top-bar] h1", text: "Step 1")

    assert_equal [ [ "spring-sale", "Step 1", nil ] ], ApplicationController.funnel_additions.map { |key, added, open| [ key, added.name, open ] }
  end

  test "a staff member removes a page from the sequence's list after confirming on the screen" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, removes_page_method: :remove_funnel_page)
    KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")
    KeystoneUi::Pages::Page.create!(name: "Thanks", slug: "thanks", place: "funnel", sequence_key: "spring-sale")
    visit "/pages/manage/sequences/funnel/spring-sale"

    within("[data-sequence-page]", text: "Thanks") { click_on "Remove" }
    click_on "Remove"

    assert_selector "[data-sequence-page] a", count: 1, text: "Landing"
  end
end

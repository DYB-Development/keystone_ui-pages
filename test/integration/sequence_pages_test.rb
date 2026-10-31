# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::SequencePagesTest < ActionDispatch::IntegrationTest
  setup do
    ApplicationController.funnel_additions = []
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)
  end

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.owner_method = nil
    KeystoneUi::Pages.refusal_method = nil
  end

  test "a page added to a sequence is in the sequence's place, belongs to the current owner and carries the sequence's key" do
    KeystoneUi::Pages.owner_method = :current_team
    team = Team.create!(name: "Acme")

    post "/pages/manage/sequences/funnel/spring-sale/pages", params: { page: { name: "Landing" } }, headers: { "X-Team" => "Acme" }

    page = KeystoneUi::Pages::Page.find_by(name: "Landing")
    assert_equal [ "funnel", team, "spring-sale" ], [ page.place, page.owner, page.sequence_key ]
  end

  test "adding a page calls the host's add page method with the sequence's key, the new page and the page that was open" do
    landing = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel", sequence_key: "spring-sale")

    post "/pages/manage/sequences/funnel/spring-sale/pages", params: { page: { name: "Thanks" }, after_id: landing.id }

    assert_equal [ [ "spring-sale", KeystoneUi::Pages::Page.find_by(name: "Thanks"), landing ] ], ApplicationController.funnel_additions
  end

  test "adding a page to a sequence the host answers nothing for gets the host's refusal and adds no page" do
    KeystoneUi::Pages.refusal_method = :refuse_page

    post "/pages/manage/sequences/funnel/spring-sale/pages", params: { page: { name: "Landing" } }, headers: { "X-Sequence" => "refused" }

    assert_equal [ 403, 0 ], [ response.status, KeystoneUi::Pages::Page.count ]
  end

  test "adding a page sends staff to the sequence screen on the new page" do
    post "/pages/manage/sequences/funnel/spring-sale/pages", params: { page: { name: "Landing" } }

    assert_redirected_to "/pages/manage/sequences/funnel/spring-sale?page_id=#{KeystoneUi::Pages::Page.find_by(name: "Landing").id}"
  end

  test "the form for adding a page to a sequence shows the place's default name as the Name field's placeholder" do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, default_name: "Step", sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)

    get "/pages/manage/sequences/funnel/spring-sale/pages/new"

    assert_equal "Step 1", Nokogiri::HTML(response.body).at_css("input[name='page[name]']")&.[]("placeholder")
  end

  test "a page added to a sequence is served at its own public address once it is published" do
    post "/pages/manage/sequences/funnel/spring-sale/pages", params: { page: { name: "Landing" } }
    page = KeystoneUi::Pages::Page.find_by(name: "Landing")
    post "/pages/manage/pages/#{page.id}/publish"

    get "/pages/#{page.slug}"

    assert_response :success
  end
end

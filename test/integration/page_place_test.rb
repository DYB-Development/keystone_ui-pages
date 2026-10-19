# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PagePlaceTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_portal" => "Client portal" }
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "the new page form offers the places the host names" do
    get "/pages/manage/pages/new"

    options = Nokogiri::HTML(response.body).css("select[name='page[place]'] option").map { |option| [ option.text, option["value"] ] }
    assert_equal [ [ "Marketing site", "marketing" ], [ "Client portal", "client_portal" ] ], options
  end

  test "a page created from the new page form keeps the place the editor chose" do
    post "/pages/manage/pages", params: { page: { name: "Pricing", slug: "pricing", place: "client_portal" } }

    assert_equal "client_portal", KeystoneUi::Pages::Page.find_by(slug: "pricing").place
  end
end

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
end

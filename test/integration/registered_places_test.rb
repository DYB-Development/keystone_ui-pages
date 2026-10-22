# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::RegisteredPlacesTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a registered place is offered on the new page form under its label" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report")

    get "/pages/manage/pages/new"

    assert_equal [ [ "Client report", "client_report" ] ], Nokogiri::HTML(response.body).css("select[name='page[place]'] option").map { |option| [ option.text, option["value"] ] }
  end
end

# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PlaceChoiceTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "the new page form and page settings offer only the host's places, with no blank choice" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.register_place("client_report", label: "Client report", slug: false)
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")

    choices = [ "/pages/manage/pages/new", "/pages/manage/pages/#{page.id}/edit" ].map do |path|
      get path
      Nokogiri::HTML(response.body).css("select[name='page[place]'] option").map { |option| option["value"] }
    end

    assert_equal [ %w[marketing client_report], %w[marketing client_report] ], choices
  end
end

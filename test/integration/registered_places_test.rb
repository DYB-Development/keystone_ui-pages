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

  test "a new page form opened with a place whose pages have a URL slug asks for the URL slug" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")

    get "/pages/manage/pages/new", params: { place: "marketing" }

    assert_equal 1, Nokogiri::HTML(response.body).css("input[name='page[slug]']").size
  end

  test "the new page form shows the name an unnamed page will get as the Name field's placeholder" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", default_name: "Report template", slug: false)
    KeystoneUi::Pages::Page.create!(name: "Report template 1", slug: "first", place: "client_report")

    get "/pages/manage/pages/new", params: { place: "client_report" }

    assert_equal "Report template 2", Nokogiri::HTML(response.body).at_css("input[name='page[name]']")["placeholder"]
  end

  test "the new page form and page settings label the slug field URL slug" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    labels = [ "/pages/manage/pages/new", "/pages/manage/pages/#{page.id}/edit" ].map do |path|
      get path
      Nokogiri::HTML(response.body).css("label").map(&:text).grep(/slug|Address/i)
    end

    assert_equal [ [ "URL slug" ], [ "URL slug" ] ], labels
  end

  test "two places registered separately each keep their own label, word and URL slug setting" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.register_place("client_report", label: "Client report", default_name: "Report template", slug: false)

    assert_equal(
      { "marketing" => { label: "Marketing site", default_name: "Page", slug: true },
        "client_report" => { label: "Client report", default_name: "Report template", slug: false } },
      KeystoneUi::Pages.place_settings
    )
  end
end

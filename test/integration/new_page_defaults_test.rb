# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::NewPageDefaultsTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_report" => "Client report" }
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a page created with no name in a place registered with a word is named with that word and a number" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", default_name: "Report template")

    post "/pages/manage/pages", params: { page: { name: "", slug: "pricing", place: "client_report" } }

    assert_equal "Report template 1", KeystoneUi::Pages::Page.find_by(slug: "pricing").name
  end

  test "a new page form opened with a place carries that place to the page it creates" do
    get "/pages/manage/pages/new", params: { place: "client_report" }

    assert_equal "client_report", Nokogiri::HTML(response.body).at_css("input[type=hidden][name='page[place]']")&.[]("value")
  end

  test "a new page form opened with a place whose pages have no URL slug asks for no URL slug and no place" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", slug: false)

    get "/pages/manage/pages/new", params: { place: "client_report" }

    assert_empty Nokogiri::HTML(response.body).css("input[name='page[slug]'], select[name='page[place]']")
  end

  test "a new page form opened with no place still asks for a name and a URL slug" do
    get "/pages/manage/pages/new"

    assert_equal 2, Nokogiri::HTML(response.body).css("input[name='page[name]'], input[name='page[slug]']").size
  end

  test "a page given a place the host has not defined is refused with the new page form shown again" do
    post "/pages/manage/pages", params: { page: { name: "Pricing", slug: "pricing", place: "storefront" } }

    assert_equal [ 422, 1 ], [ response.status, Nokogiri::HTML(response.body).css("form[action='/pages/manage/pages'] input[name='page[name]']").size ]
  end

  test "a page created with no name in a place the host gives no word is named Page and a number" do
    post "/pages/manage/pages", params: { page: { name: "", slug: "pricing", place: "marketing" } }

    assert_equal "Page 1", KeystoneUi::Pages::Page.find_by(slug: "pricing").name
  end

  test "a page created with no name takes the number after the highest default name already used" do
    KeystoneUi::Pages::Page.create!(name: "Page 3", slug: "third", place: "marketing")

    post "/pages/manage/pages", params: { page: { name: "", slug: "pricing", place: "marketing" } }

    assert_equal "Page 4", KeystoneUi::Pages::Page.find_by(slug: "pricing").name
  end

  test "a page created with no URL slug is given a random one" do
    post "/pages/manage/pages", params: { page: { name: "Pricing", slug: "", place: "marketing" } }

    assert_match(/\A\h{8}\z/, KeystoneUi::Pages::Page.find_by(name: "Pricing").slug)
  end
end

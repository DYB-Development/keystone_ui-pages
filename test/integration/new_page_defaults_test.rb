# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::NewPageDefaultsTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_report" => "Client report" }
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a new page form opened with a place carries that place to the page it creates" do
    get "/pages/manage/pages/new", params: { place: "client_report" }

    assert_equal "client_report", Nokogiri::HTML(response.body).at_css("input[type=hidden][name='page[place]']")&.[]("value")
  end

  test "a new page form opened with a place asks for no address and no place" do
    get "/pages/manage/pages/new", params: { place: "client_report" }

    assert_empty Nokogiri::HTML(response.body).css("input[name='page[slug]'], select[name='page[place]']")
  end

  test "a new page form opened with no place still asks for a name and an address" do
    get "/pages/manage/pages/new"

    assert_equal 2, Nokogiri::HTML(response.body).css("input[name='page[name]'], input[name='page[slug]']").size
  end

  test "a page given a place the host has not defined is refused with the new page form shown again" do
    post "/pages/manage/pages", params: { page: { name: "Pricing", slug: "pricing", place: "storefront" } }

    assert_equal [ 422, 1 ], [ response.status, Nokogiri::HTML(response.body).css("form[action='/pages/manage/pages'] input[name='page[name]']").size ]
  end

  test "a page created with no name in a place the host gives no word is named Page and a number" do
    post "/pages/manage/pages", params: { page: { name: "", slug: "pricing" } }

    assert_equal "Page 1", KeystoneUi::Pages::Page.find_by(slug: "pricing").name
  end

  test "a page created with no name takes the number after the highest default name already used" do
    KeystoneUi::Pages::Page.create!(name: "Page 3", slug: "third")

    post "/pages/manage/pages", params: { page: { name: "", slug: "pricing" } }

    assert_equal "Page 4", KeystoneUi::Pages::Page.find_by(slug: "pricing").name
  end

  test "a page created with no address is given a random address" do
    post "/pages/manage/pages", params: { page: { name: "Pricing", slug: "" } }

    assert_match(/\A\h{8}\z/, KeystoneUi::Pages::Page.find_by(name: "Pricing").slug)
  end
end

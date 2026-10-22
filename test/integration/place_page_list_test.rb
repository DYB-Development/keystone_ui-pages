# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PlacePageListTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_report" => "Client report" }
    KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
    KeystoneUi::Pages::Page.create!(name: "Invoice report", slug: "invoice-report", place: "client_report")
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a page list opened with a place shows only the pages in that place" do
    get "/pages/manage/pages", params: { place: "marketing" }

    assert_equal [ "pricing" ], Nokogiri::HTML(response.body).css("tr[data-page]").map { |row| row["data-page"] }
  end

  test "the builder's Back link for a page in a place goes to that place's page list" do
    page = KeystoneUi::Pages::Page.find_by(slug: "invoice-report")

    get "/pages/manage/pages/#{page.id}"

    assert_equal "/pages/manage/pages?place=client_report", JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])["back_url"]
  end

  test "saving the settings of a page in a place returns to that place's page list" do
    page = KeystoneUi::Pages::Page.find_by(slug: "invoice-report")

    patch "/pages/manage/pages/#{page.id}", params: { page: { name: "Invoice", slug: "invoice-report", place: "client_report" } }

    assert_redirected_to "/pages/manage/pages?place=client_report"
  end

  test "archiving a page in a place returns to that place's page list" do
    post "/pages/manage/pages/#{KeystoneUi::Pages::Page.find_by(slug: "invoice-report").id}/archive"

    assert_redirected_to "/pages/manage/pages?place=client_report"
  end

  test "restoring a page in a place returns to that place's page list" do
    page = KeystoneUi::Pages::Page.find_by(slug: "invoice-report")
    page.archive

    post "/pages/manage/pages/#{page.id}/restore"

    assert_redirected_to "/pages/manage/pages?place=client_report"
  end

  test "the Show archived link on a page list opened with a place stays in that place" do
    get "/pages/manage/pages", params: { place: "client_report" }

    assert_equal "/pages/manage/pages?archived=1&place=client_report", Nokogiri::HTML(response.body).css("a").find { |link| link.text == "Show archived" }["href"]
  end

  test "the Create button on a page list opened with a place opens New page with that place" do
    get "/pages/manage/pages", params: { place: "client_report" }

    assert_equal [ "/pages/manage/pages/new?place=client_report" ], Nokogiri::HTML(response.body).css("a").select { |link| link.text.strip == "Create" }.map { |link| link["href"] }.uniq
  end
end

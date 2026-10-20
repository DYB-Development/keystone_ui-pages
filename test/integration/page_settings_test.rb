# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageSettingsTest < ActionDispatch::IntegrationTest
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
  end

  teardown do
    KeystoneUi::Pages.refusal_method = nil
    KeystoneUi::Pages.edit_check_method = nil
    KeystoneUi::Pages.owner_method = nil
  end

  test "the page list links each page to its settings" do
    get "/pages/manage/pages"

    assert_equal "/pages/manage/pages/#{@page.id}/edit", Nokogiri::HTML(response.body).at_css("[data-page='pricing'] a:contains('Settings')")&.[]("href")
  end

  test "the settings page shows the page's name and slug in editable fields" do
    get "/pages/manage/pages/#{@page.id}/edit"

    fields = Nokogiri::HTML(response.body).css("input[name='page[name]'], input[name='page[slug]']").map { |field| field["value"] }
    assert_equal [ "Pricing", "pricing" ], fields
  end

  test "the settings page shows the page's place as the chosen place" do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site", "client_portal" => "Client portal" }
    @page.update!(place: "client_portal")

    get "/pages/manage/pages/#{@page.id}/edit"

    assert_equal "client_portal", Nokogiri::HTML(response.body).at_css("select[name='page[place]'] option[selected]")&.[]("value")
  ensure
    KeystoneUi::Pages.places = nil
  end

  test "saving the settings changes the page's slug" do
    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "plans" } }

    assert_equal "plans", @page.reload.slug
  end

  test "the settings page has a Save button" do
    get "/pages/manage/pages/#{@page.id}/edit"

    assert_equal "Save", Nokogiri::HTML(response.body).at_css("form button[type='submit']")&.text&.strip
  end

  test "saving a slug another page already uses shows that the slug is taken" do
    KeystoneUi::Pages::Page.create!(name: "Plans", slug: "plans")

    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "plans" } }

    assert_equal [ 422, "Slug has already been taken" ], [ response.status, Nokogiri::HTML(response.body).at_css("[role='alert']")&.text&.strip ]
  end

  test "saving a slug another page already uses changes nothing" do
    KeystoneUi::Pages::Page.create!(name: "Plans", slug: "plans")

    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing page", slug: "plans" } }

    assert_equal [ "Pricing", "pricing" ], @page.reload.slice(:name, :slug).values
  end

  test "saving a place the host does not allow shows a validation message" do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site" }

    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "pricing", place: "client_portal" } }

    assert_equal [ 422, "Place is not included in the list" ], [ response.status, Nokogiri::HTML(response.body).at_css("[role='alert']")&.text&.strip ]
  ensure
    KeystoneUi::Pages.places = nil
  end

  test "saving a place the host does not allow changes nothing" do
    KeystoneUi::Pages.places = { "marketing" => "Marketing site" }
    @page.update!(place: "marketing")

    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing page", slug: "pricing", place: "client_portal" } }

    assert_equal [ "Pricing", "marketing" ], @page.reload.slice(:name, :place).values
  ensure
    KeystoneUi::Pages.places = nil
  end

  test "after its slug changes a published page shows at its new address and not its old one" do
    @page.publish

    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "plans" } }
    get "/pages/plans"
    new_address = response.status
    get "/pages/pricing"

    assert_equal [ 200, 404 ], [ new_address, response.status ]
  end

  test "a person the edit check allows can open and save the settings" do
    KeystoneUi::Pages.edit_check_method = :may_edit_pages?

    get "/pages/manage/pages/#{@page.id}/edit", headers: { "X-Editor" => "allowed" }
    opened = response.status
    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "plans" } }, headers: { "X-Editor" => "allowed" }

    assert_equal [ 200, "plans" ], [ opened, @page.reload.slug ]
  end

  test "a person the edit check refuses gets the host's refusal when opening the settings" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.edit_check_method = :may_edit_pages?

    get "/pages/manage/pages/#{@page.id}/edit", headers: { "X-Editor" => "refused" }

    assert_equal [ 403, "This page is not available" ], [ response.status, response.body ]
  end

  test "a person the edit check refuses gets the host's refusal when saving the settings" do
    KeystoneUi::Pages.refusal_method = :refuse_page
    KeystoneUi::Pages.edit_check_method = :may_edit_pages?

    patch "/pages/manage/pages/#{@page.id}", params: { page: { name: "Pricing", slug: "plans" } }, headers: { "X-Editor" => "refused" }

    assert_equal [ 403, "pricing" ], [ response.status, @page.reload.slug ]
  end

  test "a page belonging to another owner cannot be opened in the settings" do
    KeystoneUi::Pages.owner_method = :current_team
    Team.create!(name: "Acme")
    other = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", owner: Team.create!(name: "Globex"))

    get "/pages/manage/pages/#{other.id}/edit", headers: { "X-Team" => "Acme" }

    assert_response :not_found
  end
end

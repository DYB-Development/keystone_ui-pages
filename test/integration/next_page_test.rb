# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::NextPageTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, next_page_method: :funnel_next_page)
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "the builder offers a Next page element with a label on a page in a place that names a next page method" do
    page = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel")

    get "/pages/manage/pages/#{page.id}"

    assert_equal [ "label" ], offered(page_props, "next_page")&.dig("fields")&.pluck("key")
  end

  test "the builder does not offer a Next page element on a page in a place that names no next page method" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")

    get "/pages/manage/pages/#{page.id}"

    assert_nil offered(page_props, "next_page")
  end

  test "a visitor's Next page button leads to the address the host's next page method answers for them" do
    publish_landing

    get "/pages/landing", headers: { "X-Next-Page" => "/pages/thanks" }

    assert_equal "/pages/thanks", next_button&.[]("href")
  end

  test "a visitor the host answers no next page for sees no Next page button" do
    publish_landing

    get "/pages/landing"

    assert_nil next_button
  end

  test "each visitor's Next page button leads to the host's answer for them even after the page was drawn for someone else" do
    cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    publish_landing
    get "/pages/landing", headers: { "X-Next-Page" => "/pages/thanks" }

    get "/pages/landing", headers: { "X-Next-Page" => "/pages/pricing" }

    assert_equal "/pages/pricing", next_button&.[]("href")
  ensure
    Rails.cache = cache
  end

  test "a form on a page in a place that names a next page method offers the next page after submitting" do
    page = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel")

    get "/pages/manage/pages/#{page.id}"

    assert_includes after_submitting_options(page_props), "next_page"
  end

  test "a form on a page in a place that names no next page method does not offer the next page after submitting" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")

    get "/pages/manage/pages/#{page.id}"

    assert_equal %w[thank_you address], after_submitting_options(page_props)
  end

  private

  def after_submitting_options(props)
    offered(props, "form")["fields"].find { |field| field["key"] == "after_submitting" }["options"]
  end

  def publish_landing
    page = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", place: "funnel")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "next_page", column_id: column_id))
    page.publish
  end

  def next_button
    Nokogiri::HTML(response.body).at_css("[data-page-element] a")
  end

  def page_props
    JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
  end

  def offered(props, key)
    props["elements"].find { |element| element["key"] == key }
  end
end

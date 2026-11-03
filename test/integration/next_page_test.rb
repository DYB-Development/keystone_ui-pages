# frozen_string_literal: true

require "test_helper"

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

  private

  def page_props
    JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
  end

  def offered(props, key)
    props["elements"].find { |element| element["key"] == key }
  end
end

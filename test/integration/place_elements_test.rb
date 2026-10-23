# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PlaceElementsTest < ActionDispatch::IntegrationTest
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a place registered with elements it leaves out offers every other element in the catalog" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :form ])

    assert_equal KeystoneUi::Pages.catalog.elements.map(&:key) - [ :form ], KeystoneUi::Pages.offered_elements("client_report").map(&:key)
  end

  test "an element a host registers after its places are registered is offered in every place that does not name it" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :form ])
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ])

    assert_equal [ true, true ], %w[client_report marketing].map { |place| KeystoneUi::Pages.offered_elements(place).map(&:key).include?(:quote) }
  ensure
    KeystoneUi::Pages.catalog.leave_out(:quote)
  end

  test "the builder's element list for a page holds only the elements its place offers" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :form ])
    page = KeystoneUi::Pages::Page.create!(name: "Monthly", slug: "monthly", place: "client_report")

    get "/pages/manage/pages/#{page.id}"

    keys = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])["elements"].map { |element| element["key"] }
    assert_equal [ false, true ], [ keys.include?("form"), keys.include?("button") ]
  end
end

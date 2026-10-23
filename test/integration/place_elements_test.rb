# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

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

  test "adding an element the page's place leaves out is refused even when asked for outside the element list" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :form ])
    page = KeystoneUi::Pages::Page.create!(name: "Monthly", slug: "monthly", place: "client_report")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]

    post "/pages/manage/pages/#{page.id}/elements", params: { key: "form", column_id: column_id }, as: :json

    assert_equal [ 422, [] ], [ response.status, page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"] ]
  end

  test "moving a page to a place that leaves out an element the page holds is refused on the settings page, naming the element" do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :form ])
    page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "form", column_id: column_id))

    patch "/pages/manage/pages/#{page.id}", params: { page: { name: "Contact", slug: "contact", place: "client_report" } }

    assert_equal [ 422, true, "marketing" ], [ response.status, response.body.include?("Client report does not offer Form"), page.reload.place ]
  end

  test "checking the places raises an error naming a left-out element no catalog entry has" do
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :fomr ])

    error = assert_raises(ArgumentError) { KeystoneUi::Pages.check_places! }

    assert_equal "The place client_report leaves out fomr, which no catalog element has", error.message
  end
end

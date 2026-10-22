# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::ClickReportingBrowserTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { @received << [ event.kind, event.element ] })
    @page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing", place: "marketing")
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "clicking a button inside an element calls the handler with a click and that element's id at the public address and in a host view" do
    button_id = add_element("button", "label" => "Get a quote")
    @page_record.publish

    [ "/pages/pricing", "/products/pricing" ].each do |path|
      visit path
      click_on "Get a quote"
    end

    assert_equal [ [ "click", button_id ] ] * 2, wait_for { clicks.presence if clicks.size == 2 }
  end

  private

  def clicks
    @received.dup.select { |kind, _element| kind == "click" }
  end

  def add_element(key, fields)
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@page_record.document, key, column_id: column_id)
    element = document["sections"][0]["rows"][0]["columns"][0]["elements"].last
    fields.each { |field, value| document = KeystoneUi::Pages::Operations.set(document, element_id: element["id"], field: field, value: value) }
    @page_record.update!(document: document)
    element["id"]
  end
end

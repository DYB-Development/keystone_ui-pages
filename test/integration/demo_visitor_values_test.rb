# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::DemoVisitorValuesTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.values_method = :demo_page_values
    page = KeystoneUi::Pages::Page.create!(name: "Course", slug: "course")
    document = KeystoneUi::Pages::Operations.add_section(page.document)
    columns = document["sections"].map { |section| section["rows"][0]["columns"][0]["id"] }
    document = KeystoneUi::Pages::Operations.add(document, "button", column_id: columns[0])
    document = KeystoneUi::Pages::Operations.add(document, "button", column_id: columns[0])
    document = KeystoneUi::Pages::Operations.add(document, "button", column_id: columns[1])
    buy, open = document["sections"][0]["rows"][0]["columns"][0]["elements"]
    buy.merge!("fields" => { "label" => "Buy" }, "show_when" => { "value" => "purchased", "equals" => "no" })
    open.merge!("fields" => { "label" => "Open" }, "show_when" => { "value" => "purchased", "equals" => "yes" })
    document["sections"][1]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"] = "Claim client discount"
    document["sections"][1]["show_when"] = { "value" => "signed_in", "equals" => "yes" }
    page.update!(document: document)
    page.publish
  end

  teardown do
    KeystoneUi::Pages.values_method = nil
  end

  test "a client who purchased sees Open and the client offer but not Buy" do
    get "/demo/visitor/purchased_client"

    get "/pages/course"

    assert_equal [ "Open", "Claim client discount" ], buttons
  end

  test "an anonymous visitor sees Buy but neither Open nor the client offer" do
    get "/demo/visitor/visitor"

    get "/pages/course"

    assert_equal [ "Buy" ], buttons
  end

  private

  def buttons
    css_select("[data-live-page] .ks-button").map { |button| button.text.strip }
  end
end

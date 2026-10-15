# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::NodeConditionTest < ActionDispatch::IntegrationTest
  setup { KeystoneUi::Pages::Values.names = { "audience" => "Audience" } }
  teardown { KeystoneUi::Pages::Values.names = {} }

  test "setting a condition through the builder's endpoint saves it on the row" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page.document["sections"][0]["rows"][0]["id"]

    post "/pages/manage/pages/#{page.id}/nodes/#{row_id}/condition", params: { name: "audience", equals: "internal" }, as: :json

    assert_equal({ "value" => "audience", "equals" => "internal" }, page.reload.document["sections"][0]["rows"][0]["show_when"])
  end
end

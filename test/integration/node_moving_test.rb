# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::NodeMovingTest < ActionDispatch::IntegrationTest
  test "moving a node through the builder's endpoint saves it in its new place" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    row_id = page.document["sections"][0]["rows"][0]["id"]
    document = KeystoneUi::Pages::Operations.add_column(page.document, row_id: row_id)
    first, second = document["sections"][0]["rows"][0]["columns"].map { |column| column["id"] }
    page.update!(document: KeystoneUi::Pages::Operations.add(document, "button", column_id: first))
    element_id = page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    post "/pages/manage/pages/#{page.id}/nodes/#{element_id}/move", params: { into: second, position: 0 }, as: :json

    assert_equal [ [], [ element_id ] ], page.reload.document["sections"][0]["rows"][0]["columns"].map { |column| column["elements"].map { |element| element["id"] } }
  end

  test "duplicating a node through the builder's endpoint saves a copy right after it" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "button", column_id: column_id))
    element_id = page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    post "/pages/manage/pages/#{page.id}/nodes/#{element_id}/duplicate", as: :json

    assert_equal [ 2, element_id ], [ page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"].size, page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"] ]
  end
end

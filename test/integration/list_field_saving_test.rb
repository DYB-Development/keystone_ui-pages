# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::ListFieldSavingTest < ActionDispatch::IntegrationTest
  test "setting a list field through the builder's endpoint saves its entries" do
    page = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "accordion", column_id: column_id))
    element_id = page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    entries = [ { "question" => "Price?", "answer" => "Free." } ]

    patch "/pages/manage/pages/#{page.id}/elements/#{element_id}", params: { field: "items", value: entries }, as: :json

    assert_equal entries, page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["items"]
  end
end

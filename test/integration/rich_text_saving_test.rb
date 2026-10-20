# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::RichTextSavingTest < ActionDispatch::IntegrationTest
  test "setting a paragraph's rich text through the builder's endpoint saves its markup" do
    page = KeystoneUi::Pages::Page.create!(name: "Home", slug: "home")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(page.document, "paragraph", column_id: column_id))
    element_id = page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    patch "/pages/manage/pages/#{page.id}/elements/#{element_id}", params: { field: "text", value: { html: "<p>Hi <a href=\"/about\">there</a></p>" } }, as: :json

    assert_equal({ "html" => "<p>Hi <a href=\"/about\">there</a></p>" }, page.reload.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["text"])
  end
end

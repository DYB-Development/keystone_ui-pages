# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::DocumentReplacementTest < ActionDispatch::IntegrationTest
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    @replacement = KeystoneUi::Pages::Document.blank
    column_id = @replacement["sections"][0]["rows"][0]["columns"][0]["id"]
    @replacement = KeystoneUi::Pages::Operations.add(@replacement, "button", column_id: column_id)
  end

  test "sending a whole document that passes the catalog checks replaces the page's draft" do
    put "/pages/manage/pages/#{@page.id}/document", params: { document: @replacement }, as: :json

    assert_equal @replacement, @page.reload.document
  end
end

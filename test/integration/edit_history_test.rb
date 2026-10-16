# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::EditHistoryTest < ActionDispatch::IntegrationTest
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    @blank = @page.document
    @column_id = @blank["sections"][0]["rows"][0]["columns"][0]["id"]
  end

  test "an edit made in the builder is undone through the builder's undo endpoint" do
    post "/pages/manage/pages/#{@page.id}/elements", params: { key: "button", column_id: @column_id }, as: :json

    post "/pages/manage/pages/#{@page.id}/undo", as: :json

    assert_equal @blank, @page.reload.document
  end

  test "an undone builder edit is put back through the builder's redo endpoint" do
    post "/pages/manage/pages/#{@page.id}/elements", params: { key: "button", column_id: @column_id }, as: :json
    edited = @page.reload.document
    post "/pages/manage/pages/#{@page.id}/undo", as: :json

    post "/pages/manage/pages/#{@page.id}/redo", as: :json

    assert_equal edited, @page.reload.document
  end

  test "choosing a sample in the builder is not an edit that can be undone" do
    post "/pages/manage/pages/#{@page.id}/sample", params: { choice: "acme" }, as: :json

    assert_equal [], @page.reload.undo_history
  end

  test "the builder is told whether there is anything to undo or redo after each change" do
    post "/pages/manage/pages/#{@page.id}/elements", params: { key: "button", column_id: @column_id }, as: :json
    after_edit = response.parsed_body.slice("undoable", "redoable")

    post "/pages/manage/pages/#{@page.id}/undo", as: :json

    assert_equal [ { "undoable" => true, "redoable" => false }, { "undoable" => false, "redoable" => true } ], [ after_edit, response.parsed_body.slice("undoable", "redoable") ]
  end

  test "publishing does not change what can be undone" do
    post "/pages/manage/pages/#{@page.id}/elements", params: { key: "button", column_id: @column_id }, as: :json

    post "/pages/manage/pages/#{@page.id}/publish"
    post "/pages/manage/pages/#{@page.id}/undo", as: :json

    assert_equal @blank, @page.reload.document
  end
end

# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::DrawingHelperTest < ActionView::TestCase
  helper KeystoneUiHelper
  include KeystoneUi::Pages::DrawingHelper

  setup do
    @document = KeystoneUi::Pages::Document.blank
  end

  test "a section is drawn with keystone_ui's class for its spacing" do
    @document["sections"][0]["spacing"] = "lg"

    render html: drawn_document(@document)

    assert_select "section.ks-pages-section.ks-section-lg"
  end

  test "a row is drawn as a twelve-column grid with keystone_ui's class for its gap" do
    @document["sections"][0]["rows"][0]["gap"] = "xl"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-row.grid.grid-cols-12.ks-grid-gap-xl"
  end

  test "a column is drawn with its widths for narrow and wide screens" do
    column = @document["sections"][0]["rows"][0]["columns"][0]
    column["narrow"] = "1/2"
    column["wide"] = "1/3"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-column.col-span-6.sm\\:col-span-4"
  end

  test "a column is drawn with its vertical alignment" do
    @document["sections"][0]["rows"][0]["columns"][0]["align"] = "bottom"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-column.justify-end"
  end

  test "an element is drawn inside a wrapper carrying its horizontal alignment" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["align"] = "center"

    render html: drawn_document(added)

    assert_select "div.ks-pages-element.flex.justify-center > .ks-button"
  end

  test "a number field reaches its component as a number" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "progress", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "value" => "40", "max" => "80" }

    render html: drawn_document(added)

    assert_select ".ks-progress-bar[style*='50%']"
  end

  test "a one of a list field reaches its component as the chosen option" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "message" => "Saved", "type" => "success" }

    render html: drawn_document(added)

    assert_select ".ks-alert.ks-alert-success"
  end

  test "a yes or no field reaches its component as true or false" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "message" => "Saved", "type" => "info", "dismissible" => "false" }

    render html: drawn_document(added)

    assert_select ".ks-alert-dismiss", 0
  end

  test "a field with no value reaches its component as the field's default" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "alert", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "message" => "Saved" }

    render html: drawn_document(added)

    assert_select ".ks-alert.ks-alert-info"
  end

  test "an element whose component takes nested content draws its body field as that content" do
    column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@document, "code", column_id: column_id)
    added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"] = { "code" => "puts 1", "language" => "ruby" }

    render html: drawn_document(added)

    assert_select ".ks-pages-element", text: /puts 1/
  end
end

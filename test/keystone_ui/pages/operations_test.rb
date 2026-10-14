# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::OperationsTest < Minitest::Test
  UUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  def setup
    @document = KeystoneUi::Pages::Document.blank
    @column_id = @document["sections"][0]["rows"][0]["columns"][0]["id"]
  end

  def test_adding_an_element_puts_it_in_the_column_with_a_new_id
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: @column_id)

    elements = added["sections"][0]["rows"][0]["columns"][0]["elements"]
    assert_equal [ [ "button", true ] ], elements.map { |element| [ element["key"], element["id"].match?(UUID) ] }
  end

  def test_adding_an_element_leaves_the_original_document_unchanged
    original = JSON.generate(@document)

    KeystoneUi::Pages::Operations.add(@document, "button", column_id: @column_id)

    assert_equal original, JSON.generate(@document)
  end

  def test_setting_a_field_changes_that_fields_value
    added = KeystoneUi::Pages::Operations.add(@document, "button", column_id: @column_id)
    element_id = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]

    changed = KeystoneUi::Pages::Operations.set(added, element_id: element_id, field: "label", value: "Get a quote")

    assert_equal({ "label" => "Get a quote" }, changed["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"])
  end

  def test_adding_an_element_the_catalog_does_not_have_is_refused_naming_the_key
    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.add(@document, "carousel", column_id: @column_id)
    end

    assert_equal "No element is registered as carousel", refusal.message
  end
end

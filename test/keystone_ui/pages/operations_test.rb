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
end

# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::MoveOperationsTest < Minitest::Test
  def setup
    document = KeystoneUi::Pages::Document.blank
    row_id = document["sections"][0]["rows"][0]["id"]
    document = KeystoneUi::Pages::Operations.add_column(document, row_id: row_id)
    @first, @second = document["sections"][0]["rows"][0]["columns"].map { |column| column["id"] }
    3.times { document = KeystoneUi::Pages::Operations.add(document, "button", column_id: @first) }
    @document = document
    @elements = document["sections"][0]["rows"][0]["columns"][0]["elements"].map { |element| element["id"] }
  end

  def test_moving_an_element_to_another_column_puts_it_there_and_keeps_the_others_in_order
    moved = KeystoneUi::Pages::Operations.move(@document, node_id: @elements[1], into: @second, position: 0)

    assert_equal [ [ @elements[0], @elements[2] ], [ @elements[1] ] ], element_ids(moved)
  end

  private

  def element_ids(document)
    document["sections"][0]["rows"][0]["columns"].map { |column| column["elements"].map { |element| element["id"] } }
  end
end

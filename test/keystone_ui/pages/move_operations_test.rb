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

  def test_moving_an_element_to_another_place_in_its_column_keeps_the_others_in_order
    moved = KeystoneUi::Pages::Operations.move(@document, node_id: @elements[0], into: @first, position: 2)

    assert_equal [ [ @elements[1], @elements[2], @elements[0] ], [] ], element_ids(moved)
  end

  def test_moving_a_row_to_another_section_takes_its_columns_and_elements_with_it
    document = KeystoneUi::Pages::Operations.add_section(@document)
    row = document["sections"][0]["rows"][0]

    moved = KeystoneUi::Pages::Operations.move(document, node_id: row["id"], into: document["sections"][1]["id"], position: 0)

    assert_equal [ [], [ row, document["sections"][1]["rows"][0] ] ], moved["sections"].map { |section| section["rows"] }
  end

  def test_removing_an_element_returns_a_document_without_it
    removed = KeystoneUi::Pages::Operations.remove(@document, node_id: @elements[1])

    assert_equal [ [ @elements[0], @elements[2] ], [] ], element_ids(removed)
  end

  def test_moving_a_node_whose_id_is_not_in_the_document_is_refused_naming_the_id
    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.move(@document, node_id: "missing", into: @second, position: 0)
    end

    assert_equal "Nothing in this page has the id missing", refusal.message
  end

  def test_removing_a_node_whose_id_is_not_in_the_document_is_refused_naming_the_id
    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.remove(@document, node_id: "missing")
    end

    assert_equal "Nothing in this page has the id missing", refusal.message
  end

  def test_moving_a_node_into_one_of_its_own_children_is_refused
    section = @document["sections"][0]

    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.move(@document, node_id: section["id"], into: section["rows"][0]["id"], position: 0)
    end

    assert_equal "A section cannot be moved into something inside it", refusal.message
  end

  def test_duplicating_an_element_places_a_copy_with_a_new_id_right_after_it
    duplicated = KeystoneUi::Pages::Operations.duplicate(@document, node_id: @elements[0])

    ids = element_ids(duplicated)[0]
    assert_equal [ 4, @elements[0], @elements[1], true ], [ ids.size, ids[0], ids[2], !@elements.include?(ids[1]) ]
  end

  private

  def element_ids(document)
    document["sections"][0]["rows"][0]["columns"].map { |column| column["elements"].map { |element| element["id"] } }
  end
end

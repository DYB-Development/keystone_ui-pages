# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::LayoutOperationsTest < Minitest::Test
  def setup
    @document = KeystoneUi::Pages::Document.blank
    @section = @document["sections"][0]
    @row = @section["rows"][0]
    @column = @row["columns"][0]
  end

  def test_adding_a_section_appends_one_holding_a_row_with_a_column
    added = KeystoneUi::Pages::Operations.add_section(@document)

    assert_equal [ 2, 1, 1 ], [ added["sections"].size, added["sections"][1]["rows"].size, added["sections"][1]["rows"][0]["columns"].size ]
  end

  def test_adding_a_row_to_a_section_appends_one_holding_a_column
    added = KeystoneUi::Pages::Operations.add_row(@document, section_id: @section["id"])

    assert_equal [ 2, 1 ], [ added["sections"][0]["rows"].size, added["sections"][0]["rows"][1]["columns"].size ]
  end

  def test_adding_a_column_to_a_row_appends_an_empty_one
    added = KeystoneUi::Pages::Operations.add_column(@document, row_id: @row["id"])

    assert_equal [ 2, [] ], [ added["sections"][0]["rows"][0]["columns"].size, added["sections"][0]["rows"][0]["columns"][1]["elements"] ]
  end

  def test_arranging_a_column_stores_its_wide_width
    arranged = KeystoneUi::Pages::Operations.arrange(@document, node_id: @column["id"], setting: "wide", value: "1/2")

    assert_equal "1/2", arranged["sections"][0]["rows"][0]["columns"][0]["wide"]
  end

  def test_arranging_a_section_stores_a_shaded_background
    arranged = KeystoneUi::Pages::Operations.arrange(@document, node_id: @section["id"], setting: "background", value: "shaded")

    assert_equal "shaded", arranged["sections"][0]["background"]
  end

  def test_arranging_a_section_stores_one_of_keystone_uis_page_widths
    arranged = KeystoneUi::Pages::Operations.arrange(@document, node_id: @section["id"], setting: "width", value: "lg")

    assert_equal "lg", arranged["sections"][0]["width"]
  end

  def test_arranging_a_node_with_a_value_it_does_not_offer_is_refused
    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.arrange(@document, node_id: @section["id"], setting: "spacing", value: "huge")
    end

    assert_equal "A section's spacing cannot be huge", refusal.message
  end

  def test_a_row_whose_column_widths_add_up_to_more_than_the_row_is_refused_naming_the_row
    widened = KeystoneUi::Pages::Operations.add_column(@document, row_id: @row["id"])
    widened = KeystoneUi::Pages::Operations.arrange(widened, node_id: @column["id"], setting: "wide", value: "2/3")
    second = widened["sections"][0]["rows"][0]["columns"][1]["id"]

    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.arrange(widened, node_id: second, setting: "wide", value: "1/2")
    end

    assert_equal "Row 1 of section 1 is wider than the page on wide screens", refusal.message
  end

  def test_removing_a_section_row_or_column_that_holds_elements_is_refused_saying_how_many
    filled = KeystoneUi::Pages::Operations.add(@document, "button", column_id: @column["id"])
    filled = KeystoneUi::Pages::Operations.add(filled, "button", column_id: @column["id"])

    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.remove(filled, node_id: @section["id"])
    end

    assert_equal "This section holds 2 elements, so it cannot be removed", refusal.message
  end

  def test_removing_an_empty_column_takes_it_out_of_its_row
    widened = KeystoneUi::Pages::Operations.add_column(@document, row_id: @row["id"])
    second = widened["sections"][0]["rows"][0]["columns"][1]["id"]

    narrowed = KeystoneUi::Pages::Operations.remove(widened, node_id: second)

    assert_equal [ @column["id"] ], narrowed["sections"][0]["rows"][0]["columns"].map { |column| column["id"] }
  end

  def test_removing_a_column_that_holds_one_element_is_refused_in_the_singular
    filled = KeystoneUi::Pages::Operations.add(@document, "button", column_id: @column["id"])

    refusal = assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.remove(filled, node_id: @column["id"])
    end

    assert_equal "This column holds 1 element, so it cannot be removed", refusal.message
  end
end

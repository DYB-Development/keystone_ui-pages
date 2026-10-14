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
end

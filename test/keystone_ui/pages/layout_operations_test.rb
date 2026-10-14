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
end

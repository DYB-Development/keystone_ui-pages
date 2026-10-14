# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"

class KeystoneUi::Pages::DocumentTest < Minitest::Test
  def test_a_new_document_holds_one_section_with_one_row_with_one_column_and_a_schema_version
    document = KeystoneUi::Pages::Document.blank

    assert_equal [ 1, 1, 1, [], 1 ], [
      document["sections"].size,
      document["sections"][0]["rows"].size,
      document["sections"][0]["rows"][0]["columns"].size,
      document["sections"][0]["rows"][0]["columns"][0]["elements"],
      document["schema_version"]
    ]
  end
end

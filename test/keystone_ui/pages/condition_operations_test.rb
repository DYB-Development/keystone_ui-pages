# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::ConditionOperationsTest < Minitest::Test
  def setup
    @document = KeystoneUi::Pages::Document.blank
    @row = @document["sections"][0]["rows"][0]
  end

  def test_showing_a_row_only_when_a_host_value_equals_a_chosen_value_stores_that_condition
    shown = KeystoneUi::Pages::Operations.show_when(@document, node_id: @row["id"], name: "audience", equals: "internal")

    assert_equal({ "value" => "audience", "equals" => "internal" }, shown["sections"][0]["rows"][0]["show_when"])
  end
end

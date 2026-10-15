# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::ConditionOperationsTest < Minitest::Test
  def setup
    @document = KeystoneUi::Pages::Document.blank
    @row = @document["sections"][0]["rows"][0]
    KeystoneUi::Pages::Values.names = { "audience" => "Audience" }
  end

  def teardown
    KeystoneUi::Pages::Values.names = {}
  end

  def test_showing_a_row_only_when_a_host_value_equals_a_chosen_value_stores_that_condition
    shown = KeystoneUi::Pages::Operations.show_when(@document, node_id: @row["id"], name: "audience", equals: "internal")

    assert_equal({ "value" => "audience", "equals" => "internal" }, shown["sections"][0]["rows"][0]["show_when"])
  end

  def test_a_column_cannot_be_given_a_condition
    assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.show_when(@document, node_id: @row["columns"][0]["id"], name: "audience", equals: "internal")
    end
  end

  def test_a_condition_on_a_value_the_host_does_not_name_is_refused
    assert_raises(KeystoneUi::Pages::InvalidDocument) do
      KeystoneUi::Pages::Operations.show_when(@document, node_id: @row["id"], name: "mood", equals: "happy")
    end
  end

  def test_clearing_a_condition_shows_the_row_always_again
    shown = KeystoneUi::Pages::Operations.show_when(@document, node_id: @row["id"], name: "audience", equals: "internal")

    cleared = KeystoneUi::Pages::Operations.show_when(shown, node_id: @row["id"], name: nil, equals: nil)

    refute cleared["sections"][0]["rows"][0].key?("show_when")
  end
end

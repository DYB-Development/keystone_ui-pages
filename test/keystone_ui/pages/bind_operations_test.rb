# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/values"

class KeystoneUi::Pages::BindOperationsTest < Minitest::Test
  def setup
    KeystoneUi::Pages::Values.names = { "client_name" => "Client name" }
    document = KeystoneUi::Pages::Document.blank
    column_id = document["sections"][0]["rows"][0]["columns"][0]["id"]
    @document = KeystoneUi::Pages::Operations.add(document, "button", column_id: column_id)
    @element_id = @document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
  end

  def teardown
    KeystoneUi::Pages::Values.names = {}
  end

  def test_binding_a_field_stores_the_value_name_and_its_fallback_in_place_of_fixed_text
    bound = KeystoneUi::Pages::Operations.bind(@document, element_id: @element_id, field: "label", name: "client_name", fallback: "Our client")

    assert_equal({ "value" => "client_name", "fallback" => "Our client" }, bound["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["label"])
  end
end

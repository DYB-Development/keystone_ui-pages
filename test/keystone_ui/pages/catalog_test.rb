# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/catalog"

class KeystoneUi::Pages::CatalogTest < Minitest::Test
  def test_a_host_registers_an_element_by_key_name_component_and_fields
    catalog = KeystoneUi::Pages::Catalog.new
    fields = [ { key: :title, label: "Title" } ]

    catalog.register(key: :card, name: "Card", component: :ui_card, fields: fields)

    assert_equal KeystoneUi::Pages::Catalog::Element.new(key: :card, name: "Card", component: :ui_card, fields: fields), catalog.find("card")
  end
end

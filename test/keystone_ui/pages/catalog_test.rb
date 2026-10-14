# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/catalog"

class KeystoneUi::Pages::CatalogTest < Minitest::Test
  def test_a_host_registers_an_element_by_key_name_component_and_fields
    catalog = KeystoneUi::Pages::Catalog.new
    fields = [ { key: :title, label: "Title" } ]

    catalog.register(key: :card, name: "Card", component: :ui_card, fields: fields)

    assert_equal KeystoneUi::Pages::Catalog::Element.new(key: :card, name: "Card", component: :ui_card, fields: fields, body: nil), catalog.find("card")
  end

  def test_a_host_names_the_field_an_element_draws_as_its_content
    catalog = KeystoneUi::Pages::Catalog.new

    catalog.register(key: :note, name: "Note", component: :ui_info, fields: [ { key: :text, label: "Text" } ], body: :text)

    assert_equal :text, catalog.find(:note).body
  end

  def test_a_host_leaves_an_element_out_of_the_catalog
    catalog = KeystoneUi::Pages::Catalog.new
    catalog.register(key: :card, name: "Card", component: :ui_card, fields: [])

    catalog.leave_out(:card)

    assert_nil catalog.find(:card)
  end
end

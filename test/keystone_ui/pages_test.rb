# frozen_string_literal: true

require "test_helper"

class KeystoneUi::PagesTest < Minitest::Test
  def test_the_catalog_offers_a_keystone_ui_button_with_a_label_and_an_address_by_default
    button = KeystoneUi::Pages.catalog.find(:button)

    assert_equal [ :ui_button, [ { key: :label, label: "Label" }, { key: :href, label: "Address" } ] ], [ button.component, button.fields ]
  end
end

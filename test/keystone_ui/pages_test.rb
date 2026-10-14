# frozen_string_literal: true

require "test_helper"

class KeystoneUi::PagesTest < Minitest::Test
  def test_the_catalog_offers_a_keystone_ui_button_with_a_label_and_an_address_by_default
    button = KeystoneUi::Pages.catalog.find(:button)

    assert_equal [ :ui_button, [ { key: :label, label: "Label" }, { key: :href, label: "Address" } ] ], [ button.component, button.fields ]
  end

  def test_the_catalog_offers_a_keystone_ui_progress_bar_with_number_fields
    progress = KeystoneUi::Pages.catalog.find(:progress)

    assert_equal [ :ui_progress, [ :number, :number, :text ] ], [ progress.component, progress.fields.map { |field| field[:kind] } ]
  end

  def test_a_host_sets_its_controller_layouts_and_the_methods_that_check_editors_and_visitors
    settings = { base_controller: "ApplicationController", layout: "marketing", editor_layout: "admin",
                 edit_check_method: :may_edit_pages?, view_check_method: :may_view_page?,
                 owner_method: :current_team, refusal_method: :refuse }

    kept = settings.to_h { |name, _| [ name, KeystoneUi::Pages.instance_variable_get(:"@#{name}") ] }
    settings.each { |name, value| KeystoneUi::Pages.public_send(:"#{name}=", value) }

    assert_equal settings, settings.to_h { |name, _| [ name, KeystoneUi::Pages.public_send(name) ] }
  ensure
    kept.each { |name, value| KeystoneUi::Pages.public_send(:"#{name}=", value) }
  end
end

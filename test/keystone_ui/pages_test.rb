# frozen_string_literal: true

require "test_helper"

class KeystoneUi::PagesTest < Minitest::Test
  def keystone_elements
    KeystoneUi::Pages::Catalog.new.tap { |catalog| KeystoneUi::Pages::KeystoneElements.register(catalog) }
  end

  def test_the_catalog_offers_a_keystone_ui_button_with_a_label_and_an_address_by_default
    button = keystone_elements.find(:button)

    assert_equal [ :ui_button, [ { key: :label, label: "Label", default: "Button" }, { key: :href, label: "Address" } ] ], [ button.component, button.fields ]
  end

  def test_the_catalog_offers_a_keystone_ui_progress_bar_with_number_fields
    progress = keystone_elements.find(:progress)

    assert_equal [ :ui_progress, [ :number, :number, :text ] ], [ progress.component, progress.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_a_keystone_ui_alert_with_a_choice_of_type_and_a_yes_or_no_dismiss
    alert = keystone_elements.find(:alert)

    assert_equal [ :ui_alert, [ :long_text, :text, :one_of, :yes_or_no ], %w[info success warning error] ],
      [ alert.component, alert.fields.map { |field| field[:kind] }, alert.fields[2][:options] ]
  end

  def test_the_alert_type_defaults_to_info
    assert_equal "info", keystone_elements.find(:alert).fields[2][:default]
  end

  def test_the_catalog_offers_keystone_ui_code_whose_code_field_is_its_content
    code = keystone_elements.find(:code)

    assert_equal [ :ui_code, :code, %i[code language caption] ], [ code.component, code.body, code.fields.map { |field| field[:key] } ]
  end

  def test_the_catalog_offers_keystone_ui_hero
    element = keystone_elements.find(:hero)

    assert_equal [ :ui_hero, [ :text, :long_text, :text, :one_of ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_cta_banner
    element = keystone_elements.find(:cta_banner)

    assert_equal [ :ui_cta_banner, [ :text, :text, :long_text ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_card
    element = keystone_elements.find(:card)

    assert_equal [ :ui_card, [ :text, :long_text, :address, :text ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_stat_card
    element = keystone_elements.find(:stat_card)

    assert_equal [ :ui_stat_card, [ :text, :text, :text, :one_of ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_figure
    element = keystone_elements.find(:figure)

    assert_equal [ :ui_figure, [ :text, :one_of ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_info
    element = keystone_elements.find(:info)

    assert_equal [ :ui_info, [ :text, :long_text ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_badge
    element = keystone_elements.find(:badge)

    assert_equal [ :ui_badge, [ :text, :one_of ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_the_catalog_offers_keystone_ui_copy_button
    element = keystone_elements.find(:copy_button)

    assert_equal [ :ui_copy_button, [ :text, :text ] ], [ element.component, element.fields.map { |field| field[:kind] } ]
  end

  def test_every_keystone_ui_element_has_an_icon_and_belongs_to_a_group
    elements = keystone_elements.elements
    groups = elements.group_by(&:group).to_h { |group, members| [ group, members.map(&:key).sort ] }
    expected = { "Basics" => %i[badge button copy_button], "Content" => %i[card cta_banner feature_grid], "Data" => %i[figure progress stat_card], "Text" => %i[accordion alert code hero info] }

    assert_equal [ expected, [] ], [ groups.sort.to_h, elements.reject(&:icon).map(&:key) ]
  end

  def test_buttons_badges_and_copy_buttons_start_at_the_start_of_their_column
    starting = keystone_elements.elements.select { |element| element.align == "start" }.map(&:key)

    assert_equal %i[badge button copy_button], starting.sort
  end

  def test_the_catalog_offers_keystone_ui_feature_grid_filled_from_a_list_field
    grid = keystone_elements.find(:feature_grid)

    assert_equal [ :ui_feature_grid, :list, %i[title description] ], [ grid.component, grid.fields.find { |field| field[:key] == :features }[:kind], grid.fields.find { |field| field[:key] == :features }[:entry].reject { |field| field[:hidden] }.map { |field| field[:key] } ]
  end

  def test_the_catalog_offers_keystone_ui_accordion_filled_from_a_list_field
    accordion = keystone_elements.find(:accordion)

    assert_equal [ :ui_accordion, :list, %i[question answer] ], [ accordion.component, accordion.fields.first[:kind], accordion.fields.first[:entry].map { |field| field[:key] } ]
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

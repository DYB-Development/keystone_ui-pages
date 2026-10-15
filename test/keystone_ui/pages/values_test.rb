# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/values"

class KeystoneUi::Pages::ValuesTest < Minitest::Test
  def teardown
    KeystoneUi::Pages::Values.names = {}
    KeystoneUi::Pages::Values.provider = nil
    KeystoneUi::Pages::Values.chooser = nil
  end

  def test_a_host_names_the_values_a_page_may_use_with_a_label_for_each
    KeystoneUi::Pages::Values.names = { "client_name" => "Client name", "score" => "Score" }

    assert_equal "Client name", KeystoneUi::Pages::Values.label("client_name")
  end

  def test_a_host_supplies_samples_a_page_can_be_drawn_with_and_the_values_of_each
    KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme", "acme" ], [ "Globex", "globex" ] ] }
    KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "client_name" => choice.capitalize } }

    assert_equal [ [ [ "Acme", "acme" ], [ "Globex", "globex" ] ], { "client_name" => "Globex" } ],
      [ KeystoneUi::Pages::Values.samples_for(:page), KeystoneUi::Pages::Values.sample(:page, "globex") ]
  end
end

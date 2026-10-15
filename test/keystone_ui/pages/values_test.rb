# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/values"

class KeystoneUi::Pages::ValuesTest < Minitest::Test
  def teardown
    KeystoneUi::Pages::Values.names = {}
  end

  def test_a_host_names_the_values_a_page_may_use_with_a_label_for_each
    KeystoneUi::Pages::Values.names = { "client_name" => "Client name", "score" => "Score" }

    assert_equal "Client name", KeystoneUi::Pages::Values.label("client_name")
  end
end

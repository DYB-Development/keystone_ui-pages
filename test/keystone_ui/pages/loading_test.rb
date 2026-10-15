# frozen_string_literal: true

require "test_helper"
require "open3"

class KeystoneUi::Pages::LoadingTest < Minitest::Test
  def test_loading_the_gem_lets_a_host_set_its_named_values_in_an_initializer
    root = KeystoneUi::Pages::Engine.root.to_s
    _out, error, status = Open3.capture3("bundle", "exec", "ruby", "-I#{root}/lib", "-e", 'require "keystone_ui-pages"; KeystoneUi::Pages::Values.names = { "a" => "A" }', chdir: root)

    assert status.success?, error
  end
end

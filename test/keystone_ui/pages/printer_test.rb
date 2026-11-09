# frozen_string_literal: true

require "test_helper"
require "open3"

class KeystoneUi::Pages::PrinterTest < ActiveSupport::TestCase
  test "a host that requires the printer file gets the error a refused PDF raises" do
    output, _status = Open3.capture2e(RbConfig.ruby, "-I", File.expand_path("../../../lib", __dir__), "-e", 'require "keystone_ui/pages/printer"; print KeystoneUi::Pages::PrintFailed.superclass')

    assert_equal "StandardError", output
  end
end

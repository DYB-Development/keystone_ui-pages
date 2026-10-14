# frozen_string_literal: true

require "rails"
require "keystone_ui"

module KeystoneUi
  module Pages
    class Engine < ::Rails::Engine
      isolate_namespace KeystoneUi::Pages
    end
  end
end

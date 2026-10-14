# frozen_string_literal: true

require "rails"
require "keystone_ui"

module KeystoneUi
  module Pages
    class Engine < ::Rails::Engine
      isolate_namespace KeystoneUi::Pages

      initializer "keystone_ui_pages.tailwind" do
        KeystoneUi.configuration.tailwind_sources << root.join("app/views/**/*.erb").to_s
        KeystoneUi.configuration.tailwind_sources << root.join("app/helpers/**/*.rb").to_s
      end
    end
  end
end

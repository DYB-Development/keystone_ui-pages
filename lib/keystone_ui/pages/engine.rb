# frozen_string_literal: true

require "rails"
require "keystone_ui"
require "keystone_ui-react"
require "keystone_ui/react/mount_helper"

module KeystoneUi
  module Pages
    class Engine < ::Rails::Engine
      isolate_namespace KeystoneUi::Pages

      initializer "keystone_ui_pages.host_helper" do
        ActiveSupport.on_load(:action_view) { include KeystoneUi::Pages::HostHelper }
      end

      initializer "keystone_ui_pages.tailwind" do
        KeystoneUi.configuration.tailwind_sources << root.join("app/views/**/*.erb").to_s
        KeystoneUi.configuration.tailwind_sources << root.join("app/helpers/**/*.rb").to_s
        KeystoneUi.configuration.tailwind_sources << root.join("app/javascript/**/*.{js,jsx}").to_s
        KeystoneUi.configuration.tailwind_sources << root.join("lib/keystone_ui/pages/**/*.rb").to_s
      end
    end
  end
end

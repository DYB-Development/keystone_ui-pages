# frozen_string_literal: true

require "keystone_ui/pages/version"
require "keystone_ui/pages/catalog"

module KeystoneUi
  module Pages
    def self.catalog
      @catalog ||= Catalog.new.tap do |catalog|
        catalog.register(key: :button, name: "Button", component: :ui_button,
          fields: [ { key: :label, label: "Label" }, { key: :href, label: "Address" } ])
      end
    end
  end
end

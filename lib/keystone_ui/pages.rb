# frozen_string_literal: true

require "keystone_ui/pages/version"
require "keystone_ui/pages/catalog"
require "keystone_ui/pages/engine"

module KeystoneUi
  module Pages
    class << self
      attr_writer :base_controller, :layout, :editor_layout
      attr_accessor :edit_check_method, :view_check_method, :owner_method, :refusal_method

      def base_controller
        @base_controller || "ActionController::Base"
      end

      def layout
        @layout || "application"
      end

      def editor_layout
        @editor_layout || "application"
      end
    end

    def self.catalog
      @catalog ||= Catalog.new.tap do |catalog|
        catalog.register(key: :button, name: "Button", component: :ui_button,
          fields: [ { key: :label, label: "Label" }, { key: :href, label: "Address" } ])
        catalog.register(key: :progress, name: "Progress", component: :ui_progress,
          fields: [ { key: :value, label: "Value", kind: :number }, { key: :max, label: "Out of", kind: :number }, { key: :label, label: "Label", kind: :text } ])
      end
    end
  end
end

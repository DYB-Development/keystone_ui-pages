# frozen_string_literal: true

require "keystone_ui/pages/version"
require "keystone_ui/pages/catalog"
require "keystone_ui/pages/keystone_elements"
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
      @catalog ||= Catalog.new.tap { |catalog| KeystoneElements.register(catalog) }
    end
  end
end

# frozen_string_literal: true

require "keystone_ui/pages/version"
require "keystone_ui/pages/catalog"
require "keystone_ui/pages/values"
require "keystone_ui/pages/keystone_elements"
require "keystone_ui/pages/engine"

module KeystoneUi
  module Pages
    class << self
      attr_writer :base_controller, :layout, :editor_layout, :pdf_stylesheet, :access_exceptions
      attr_accessor :edit_check_method, :view_check_method, :values_method, :owner_method, :refusal_method, :chrome_path

      def base_controller
        @base_controller || "ActionController::Base"
      end

      def layout
        @layout || "application"
      end

      def editor_layout
        @editor_layout || "application"
      end

      def pdf_stylesheet
        @pdf_stylesheet || "tailwind.css"
      end

      def places
        (@places || {}).merge(place_settings.transform_values { |settings| settings[:label] })
      end

      def places=(labels)
        @places = labels
        @place_settings = {}
      end

      def register_place(key, label:, default_name: "Page", slug: true)
        place_settings[key.to_s] = { label: label, default_name: default_name, slug: slug }
      end

      def place_settings
        @place_settings ||= {}
      end

      def slugged?(place)
        place_settings.dig(place.to_s, :slug) != false
      end

      def access_exceptions
        @access_exceptions || {}
      end
    end

    def self.pdf(page, values: {}, version: nil)
      require "keystone_ui/pages/pdfs"
      Pdfs.for(page, values: values, version: version)
    end

    def self.prepare_pdf(page, values: {}, version: nil)
      PdfJob.perform_later(page, values.to_h.stringify_keys, version)
    end

    def self.catalog
      @catalog ||= Catalog.new.tap { |catalog| KeystoneElements.register(catalog) }
    end
  end
end

# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Submissions
      module_function

      def form_name(form, catalog: Pages.catalog)
        setting(form, :form_name, catalog)
      end

      def thank_you(form, catalog: Pages.catalog)
        setting(form, :thank_you, catalog)
      end

      def accepted(form, submitted, catalog: Pages.catalog)
        names = Array(setting(form, :fields, catalog)).map { |field| field["name"].to_s }
        submitted.to_unsafe_h.slice(*names)
      end

      def problems(form, values, catalog: Pages.catalog)
        Array(setting(form, :fields, catalog)).each_with_object({}) do |field, found|
          found[field["name"].to_s] = "Fill this in" if field["required"].to_s == "true" && values[field["name"].to_s].blank?
        end
      end

      private_class_method def setting(form, key, catalog)
        form["fields"].fetch(key.to_s) { catalog.find(:form).fields.find { |field| field[:key] == key }[:default] }
      end
    end
  end
end

# frozen_string_literal: true

require "uri"

module KeystoneUi
  module Pages
    module Submissions
      TRAP_NAME = "keystone_ui_pages_trap"
      LIMITS = { "text" => 200, "email" => 254, "long_text" => 5000, "choice" => 200, "checkbox" => 1 }.freeze

      module_function

      def bot?(submitted)
        submitted[TRAP_NAME].present?
      end

      def form_name(form, catalog: Pages.catalog)
        setting(form, :form_name, catalog)
      end

      def thank_you(form, catalog: Pages.catalog)
        setting(form, :thank_you, catalog)
      end

      def drawing_settings(form, catalog: Pages.catalog)
        fields = Array(setting(form, :fields, catalog)).map { |field| { kind: "text" }.merge(field.to_h.symbolize_keys.compact_blank) }
        { form_name: form_name(form, catalog: catalog), fields: fields, submit_label: setting(form, :submit_label, catalog), thank_you: thank_you(form, catalog: catalog) }
      end

      def next_address(form, catalog: Pages.catalog)
        setting(form, :next_address, catalog).presence if setting(form, :after_submitting, catalog) == "address"
      end

      def choices(text)
        text.to_s.split(",").map(&:strip).reject(&:empty?)
      end

      def accepted(form, submitted, catalog: Pages.catalog)
        names = Array(setting(form, :fields, catalog)).map { |field| field["name"].to_s }
        submitted.to_unsafe_h.slice(*names)
      end

      def delivered(form, values, catalog: Pages.catalog)
        checkboxes = Array(setting(form, :fields, catalog)).select { |field| field["kind"] == "checkbox" }.map { |field| field["name"].to_s }
        values.merge(checkboxes.to_h { |name| [ name, values[name].to_s == "1" ] })
      end

      def problems(form, values, catalog: Pages.catalog)
        Array(setting(form, :fields, catalog)).each_with_object({}) do |field, found|
          message = problem(field, values[field["name"].to_s].to_s)
          found[field["name"].to_s] = message if message
        end
      end

      private_class_method def problem(field, value)
        limit = LIMITS.fetch(field["kind"].presence || "text", LIMITS["text"])
        return "Keep this to #{limit} characters or fewer" if value.length > limit
        return "Fill this in" if field["required"].to_s == "true" && value.blank?

        return "Enter an email address" if field["kind"] == "email" && value.present? && !value.match?(URI::MailTo::EMAIL_REGEXP)

        "Choose one of the options" if field["kind"] == "choice" && value.present? && !choices(field["choices"]).include?(value)
      end

      private_class_method def setting(form, key, catalog)
        form["fields"].fetch(key.to_s) { catalog.find(:form).fields.find { |field| field[:key] == key }[:default] }
      end
    end
  end
end

# frozen_string_literal: true

require "digest"
require "json"
require "securerandom"
require "keystone_ui/pages"
require "keystone_ui/pages/document"

module KeystoneUi
  module Pages
    class InvalidDocument < StandardError; end

    module Operations
      module_function

      def add(document, key, column_id:, catalog: Pages.catalog)
        defined(catalog, key)
        copied(document).tap do |changed|
          column(changed, column_id)["elements"] << { "id" => SecureRandom.uuid, "key" => key.to_s, "fields" => {} }
        end
      end

      def add_section(document)
        copied(document).tap { |changed| changed["sections"] << Document.section }
      end

      def set(document, element_id:, field:, value:, catalog: Pages.catalog)
        copied(document).tap do |changed|
          element = element(changed, element_id)
          offered(defined(catalog, element["key"]), field)
          element["fields"][field.to_s] = value
        end
      end

      def check(document, catalog: Pages.catalog)
        elements(document).each do |element|
          definition = defined(catalog, element["key"])
          element["fields"].each_key { |field| offered(definition, field) }
        end
        document
      end

      def digest(document)
        Digest::SHA256.hexdigest(JSON.generate(sorted(document)))
      end

      def sorted(value)
        case value
        when Hash then value.sort_by { |key, _| key.to_s }.to_h { |key, nested| [ key, sorted(nested) ] }
        when Array then value.map { |nested| sorted(nested) }
        else value
        end
      end

      def defined(catalog, key)
        catalog.find(key) or raise InvalidDocument, "No element is registered as #{key}"
      end

      def offered(definition, field)
        return if definition.fields.any? { |offered| offered[:key].to_s == field.to_s }

        raise InvalidDocument, "The #{definition.key} element has no #{field} field"
      end

      def copied(document)
        JSON.parse(JSON.generate(document))
      end

      def columns(document)
        document["sections"].flat_map { |section| section["rows"] }.flat_map { |row| row["columns"] }
      end

      def column(document, column_id)
        columns(document).find { |column| column["id"] == column_id }
      end

      def elements(document)
        columns(document).flat_map { |column| column["elements"] }
      end

      def element(document, element_id)
        elements(document).find { |element| element["id"] == element_id }
      end
    end
  end
end

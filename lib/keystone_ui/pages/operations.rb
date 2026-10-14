# frozen_string_literal: true

require "json"
require "securerandom"
require "keystone_ui/pages"

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

      def set(document, element_id:, field:, value:)
        copied(document).tap do |changed|
          element(changed, element_id)["fields"][field.to_s] = value
        end
      end

      def defined(catalog, key)
        catalog.find(key) or raise InvalidDocument, "No element is registered as #{key}"
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

      def element(document, element_id)
        columns(document).flat_map { |column| column["elements"] }.find { |element| element["id"] == element_id }
      end
    end
  end
end

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
      WIDTHS = %w[1/1 3/4 2/3 1/2 1/3 1/4].freeze
      ARRANGEMENTS = {
        section: { "spacing" => %w[sm md lg] },
        row: { "gap" => %w[sm md lg xl] },
        column: { "wide" => WIDTHS, "narrow" => WIDTHS, "align" => %w[top center bottom] },
        element: { "align" => %w[stretch start center end] }
      }.freeze

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

      def add_row(document, section_id:)
        copied(document).tap { |changed| node(changed, section_id)["rows"] << Document.row }
      end

      def add_column(document, row_id:)
        copied(document).tap { |changed| node(changed, row_id)["columns"] << Document.column }
      end

      def arrange(document, node_id:, setting:, value:)
        offered_arrangement(kind(document, node_id), setting.to_s, value)
        copied(document).tap do |changed|
          node(changed, node_id)[setting.to_s] = value
          fitting(changed, setting.to_s) if %w[wide narrow].include?(setting.to_s)
        end
      end

      def fitting(document, screen)
        document["sections"].each.with_index(1) do |section, section_number|
          section["rows"].each.with_index(1) do |row, row_number|
            next if row["columns"].sum { |column| Rational(column[screen] || "0") } <= 1

            raise InvalidDocument, "Row #{row_number} of section #{section_number} is wider than the page on #{screen} screens"
          end
        end
      end

      def offered_arrangement(kind, setting, value)
        return if ARRANGEMENTS.fetch(kind).fetch(setting, []).include?(value)

        raise InvalidDocument, "A #{kind}'s #{setting} cannot be #{value}"
      end

      def kind(document, node_id)
        sections = document["sections"]
        return :section if sections.any? { |section| section["id"] == node_id }
        return :row if sections.flat_map { |section| section["rows"] }.any? { |row| row["id"] == node_id }
        return :column if column(document, node_id)

        :element
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

      def nodes(document)
        sections = document["sections"]
        rows = sections.flat_map { |section| section["rows"] }
        sections + rows + columns(document) + elements(document)
      end

      def node(document, node_id)
        nodes(document).find { |node| node["id"] == node_id }
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

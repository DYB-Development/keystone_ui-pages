# frozen_string_literal: true

require "keystone_ui/pages"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/filling"

module KeystoneUi
  module Pages
    module PdfDrawing
      module_function

      def draw(document, surface, values: {})
        values = values.to_h.stringify_keys
        document["sections"].each do |section|
          section["rows"].each { |row| drawn_row(row, surface, values) }
        end
      end

      def drawn_row(row, surface, values)
        columns = row["columns"]
        share = Operations::SHARES.fetch(columns.size, "1/1")
        surface.row(columns.map { |column| Rational(column["wide"] || share) }) do |index|
          columns[index]["elements"].each { |element| drawn_element(element, surface, values) }
        end
      end

      def drawn_element(element, surface, values)
        definition = Pages.catalog.find(element["key"])
        definition.pdf.call(surface, definition.fields.to_h { |field| [ field[:key].to_sym, Filling.filled(element["fields"][field[:key].to_s], values) || field[:default] ] })
      end
    end
  end
end

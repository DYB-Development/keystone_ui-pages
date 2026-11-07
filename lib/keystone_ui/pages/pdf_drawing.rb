# frozen_string_literal: true

require "keystone_ui/pages"
require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module PdfDrawing
      module_function

      def draw(document, surface, values: {})
        document["sections"].each do |section|
          section["rows"].each { |row| drawn_row(row, surface) }
        end
      end

      def drawn_row(row, surface)
        columns = row["columns"]
        surface.row(columns.map { Rational(Operations::SHARES.fetch(columns.size, "1/1")) }) do |index|
          columns[index]["elements"].each { |element| drawn_element(element, surface) }
        end
      end

      def drawn_element(element, surface)
        definition = Pages.catalog.find(element["key"])
        definition.pdf.call(surface, definition.fields.to_h { |field| [ field[:key].to_sym, element["fields"][field[:key].to_s].presence || field[:default] ] })
      end
    end
  end
end

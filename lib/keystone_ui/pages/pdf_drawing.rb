# frozen_string_literal: true

require "keystone_ui/pages"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/filling"
require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    class NoPdfDrawing < PrintFailed; end

    module PdfDrawing
      module_function

      def draw(document, surface, values: {})
        values = values.to_h.stringify_keys
        shown(document["sections"], values).each do |section|
          shown(section["rows"], values).each { |row| drawn_row(row, surface, values) }
        end
      end

      def drawn_row(row, surface, values)
        columns = row["columns"]
        share = Operations::SHARES.fetch(columns.size, "1/1")
        surface.row(columns.map { |column| Rational(column["wide"] || share) }) do |index|
          shown(columns[index]["elements"], values).each { |element| drawn_element(element, surface, values) }
        end
      end

      def shown(nodes, values)
        nodes.reject { |node| Filling.hidden?(node, values) }
      end

      def drawn_element(element, surface, values)
        definition = Pages.catalog.find(element["key"])
        raise NoPdfDrawing, "The #{definition.name} element has no PDF drawing, so this page cannot be drawn as a PDF without Chrome." unless definition.pdf

        definition.pdf.call(surface, definition.fields.to_h { |field| [ field[:key].to_sym, Filling.filled(element["fields"][field[:key].to_s], values) || field[:default] ] })
      end
    end
  end
end

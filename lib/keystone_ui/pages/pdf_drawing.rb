# frozen_string_literal: true

require "keystone_ui/pages"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/filling"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/pdf_surface"
require "keystone_ui/pages/pdf_look"

module KeystoneUi
  module Pages
    class NoPdfDrawing < PrintFailed; end

    module PdfDrawing
      SPACING = "--ks-spacing"
      ELEMENT_GAP = 4
      ROW_GAP = 6
      SECTION_SPACING = { "sm" => 4, "md" => 6, "lg" => 8 }.freeze

      module_function

      def pdf(version, values: {})
        surface = PdfSurface.new(PdfLook.host)
        draw(version.document, surface, values: values)
        surface.render
      end

      def draw(document, surface, values: {})
        values = values.to_h.stringify_keys
        shown(document["sections"], values).each do |section|
          surface.space(SPACING, SECTION_SPACING.fetch(section["spacing"] || Operations::DEFAULTS[:section]["spacing"]))
          drawn_rows(section, surface, values)
        end
      end

      def drawn_rows(section, surface, values)
        shown(section["rows"], values).each_with_index do |row, position|
          surface.space(SPACING, ROW_GAP) if position.positive?
          drawn_row(row, surface, values)
        end
      end

      def drawn_row(row, surface, values)
        columns = row["columns"]
        share = Operations::SHARES.fetch(columns.size, "1/1")
        surface.row(columns.map { |column| Rational(column["wide"] || share) }) do |index|
          shown(columns[index]["elements"], values).each_with_index do |element, position|
            surface.space(SPACING, ELEMENT_GAP) if position.positive?
            drawn_element(element, surface, values)
          end
        end
      end

      def shown(nodes, values)
        nodes.reject { |node| Filling.hidden?(node, values) }
      end

      def drawn_element(element, surface, values)
        definition = Pages.catalog.find(element["key"])
        raise PrintFailed, "The page holds a #{element["key"]} element, which the catalog does not have, so this page cannot be drawn as a PDF." unless definition
        raise NoPdfDrawing, "The #{definition.name} element has no PDF drawing, so this page cannot be drawn as a PDF without Chrome." unless definition.pdf

        definition.pdf.call(surface, definition.fields.to_h { |field| [ field[:key].to_sym, filled_field(field, element, values) ] })
      rescue PdfSurface::UndrawableCharacter => error
        raise PrintFailed, format("The %s element holds the character %s (U+%04X), which its font cannot draw, so this page cannot be drawn as a PDF.",
                                  definition.name, error.character, error.character.ord)
      end

      def filled_field(field, element, values)
        filled = Filling.filled(element["fields"][field[:key].to_s], values) || field[:default]
        return filled unless field[:kind] == :list && filled.is_a?(Array)

        defaults = Array(field[:entry]).to_h { |part| [ part[:key], part[:default] ] }.compact
        filled.map { |entry| defaults.merge(entry.to_h.symbolize_keys.compact_blank) }
      end
    end
  end
end

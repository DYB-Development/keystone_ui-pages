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
      STRETCHED = "stretch"
      SECTION_SPACING = { "sm" => 4, "md" => 6, "lg" => 8 }.freeze
      SHADED_LOOK = { padding: [ SPACING, 0 ], fill: "--ks-color-fill-muted" }.freeze
      ROW_GAPS = { "sm" => 3, "md" => 4, "lg" => 6, "xl" => 8 }.freeze
      SIZED_SECTION_PADDING = [ SPACING, 6, 16 ].freeze
      SECTION_WIDTHS = { "sm" => "--container-2xl", "md" => "--container-4xl", "lg" => "--container-6xl", "xl" => "--container-7xl" }.freeze

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
          surface.together { shaded(section, surface) { sized(section, surface) { drawn_rows(section, surface, values) } } }
        end
      end

      def shaded(section, surface, &rows)
        section["background"] == "shaded" ? surface.box(**SHADED_LOOK, &rows) : yield
      end

      def sized(section, surface, &rows)
        width = SECTION_WIDTHS[section["width"]]
        width ? surface.box(padding: SIZED_SECTION_PADDING, width: [ width, 1 ], align: :center, &rows) : yield
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
        gap = [ SPACING, ROW_GAPS.fetch(row["gap"] || Operations::DEFAULTS[:row]["gap"]) ]
        align = columns.map { |column| (column["align"] || Operations::DEFAULTS[:column]["align"]).to_sym }
        surface.row(columns.map { |column| Rational(column["wide"] || share) }, gap: gap, grid: true, align: align) do |index|
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

        placed(element["align"] || definition.align || Operations::DEFAULTS[:element]["align"], surface) do
          definition.pdf.call(surface, definition.fields.to_h { |field| [ field[:key].to_sym, filled_field(field, element, values) ] })
        end
      rescue PdfSurface::UndrawableCharacter => error
        raise PrintFailed, format("The %s element holds the character %s (U+%04X), which its font cannot draw, so this page cannot be drawn as a PDF.",
                                  definition.name, error.character, error.character.ord)
      end

      def placed(align, surface, &drawing)
        align == STRETCHED ? yield : surface.aligned(align.to_sym, &drawing)
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

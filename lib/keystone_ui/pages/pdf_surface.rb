# frozen_string_literal: true

require "prawn"

module KeystoneUi
  module Pages
    class PdfSurface
      BOLD_WEIGHT = 600

      def initialize(look)
        @look = look
        @document = Prawn::Document.new
      end

      def text(content, size:, font: "--ks-font-body", weight: nil, color: "--ks-color-text")
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name, style: bold?(weight) ? :bold : :normal) { @document.text(content.to_s, size: size) }
      end

      def space(token, steps)
        @document.move_down(@look.points(token) * steps)
      end

      def row(widths)
        top = @document.cursor
        lowest = @document.y
        left = 0
        widths.each_with_index do |width, index|
          column_width = @document.bounds.width * width
          @document.bounding_box([ left, top ], width: column_width) do
            yield index
            lowest = [ lowest, @document.y ].min
          end
          left += column_width
        end
        @document.y = lowest
      end

      def render
        @document.render
      end

      private

      def bold?(weight)
        weight.present? && @look.weight(weight) >= BOLD_WEIGHT
      end
    end
  end
end

# frozen_string_literal: true

require "prawn"

module KeystoneUi
  module Pages
    class PdfSurface
      def initialize
        @document = Prawn::Document.new
      end

      def text(content, size:)
        @document.text(content.to_s, size: size)
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
    end
  end
end

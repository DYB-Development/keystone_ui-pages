# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfPlot
      attr_reader :width, :height

      def initialize(document, look, width, height)
        @document = document
        @look = look
        @width = width
        @height = height
        @top = document.cursor
      end

      def rect(left, top, across, down, color:, opacity: 1)
        translucent(opacity) do
          @document.fill_color(@look.color(color))
          @document.fill_rectangle(placed([ left, top ]), across, down)
        end
      end

      def line(points, width:, color:)
        @document.stroke_color(@look.color(color))
        @document.line_width(@look.points(width))
        @document.move_to(placed(points.first))
        points.drop(1).each { |point| @document.line_to(placed(point)) }
        @document.stroke
      end

      private

      def placed((left, top))
        [ left, @top - top ]
      end

      def translucent(opacity, &painting)
        opacity < 1 ? @document.transparent(opacity, &painting) : yield
      end
    end
  end
end

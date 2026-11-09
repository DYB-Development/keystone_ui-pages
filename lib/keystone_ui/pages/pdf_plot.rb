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

      def line(points, width:, color:, dash: nil)
        @document.stroke_color(@look.color(color))
        @document.line_width(@look.points(width))
        @document.dash(@look.points(dash)) if dash
        @document.move_to(placed(points.first))
        points.drop(1).each { |point| @document.line_to(placed(point)) }
        @document.stroke
        @document.undash if dash
      end

      def label(content, left, top, size:, color:, font: "--ks-font-body")
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name) { @document.draw_text(content.to_s, at: placed([ left, top ]), size: @look.points(size)) }
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

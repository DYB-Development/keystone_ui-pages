# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfPlot
      ANCHORS = { start: 0, middle: Rational(1, 2), end: 1 }.freeze

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

      def label(content, left, top, size:, color:, font: "--ks-font-body", anchor: :start)
        typeface = @look.font(font)
        points = @look.points(size)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name) do
          shift = @document.width_of(content.to_s, size: points) * ANCHORS.fetch(anchor)
          @document.draw_text(content.to_s, at: placed([ left - shift, top ]), size: points)
        end
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

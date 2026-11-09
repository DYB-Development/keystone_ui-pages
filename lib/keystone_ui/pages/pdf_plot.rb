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
          @document.fill_rectangle([ left, @top - top ], across, down)
        end
      end

      private

      def translucent(opacity, &painting)
        opacity < 1 ? @document.transparent(opacity, &painting) : yield
      end
    end
  end
end

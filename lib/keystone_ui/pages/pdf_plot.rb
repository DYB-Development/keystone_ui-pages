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
    end
  end
end

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
        translucent(opacity * @look.opacity(color)) do
          @document.fill_color(@look.color(color))
          @document.fill_rectangle(placed([ left, top ]), across, down)
        end
      end

      def line(points, width:, color:, dash: nil)
        translucent(@look.opacity(color)) do
          @document.stroke_color(@look.color(color))
          @document.line_width(@look.points(width))
          @document.dash(@look.points(dash)) if dash
          @document.move_to(placed(points.first))
          points.drop(1).each { |point| @document.line_to(placed(point)) }
          @document.stroke
          @document.undash if dash
        end
      end

      def label(content, left, top, size:, color:, font: "--ks-font-body", anchor: :start, baseline: :alphabetic)
        typeface = typeface(font)
        points = @look.points(size)
        @document.fill_color(@look.color(color))
        @document.font(typeface.name) do
          drawable!(content.to_s)
          shift = @document.width_of(content.to_s, size: points) * ANCHORS.fetch(anchor)
          @document.draw_text(content.to_s, at: placed([ left - shift, top + lowered(baseline, points) ]), size: points)
        end
      end

      def text_width(content, size:, font: "--ks-font-body")
        width = 0
        @document.font(typeface(font).name) { width = @document.width_of(content.to_s, size: @look.points(size)) }
        width
      end

      def points(length)
        @look.points(length)
      end

      private

      def drawable!(content)
        missing = content.each_char.find { |char| !char.match?(/[[:cntrl:]]/) && !@document.font.glyph_present?(char) }
        raise PdfSurface::UndrawableCharacter, missing if missing
      end

      def typeface(font)
        @look.font(font).tap { |typeface| @document.font_families[typeface.name] = typeface.files if typeface.files }
      end

      def lowered(baseline, points)
        ascender, descender = [ @document.font.ascender, @document.font.descender ].map { |height| height / @document.font_size * points }
        { alphabetic: 0, middle: (ascender - descender.abs) / 2, top: ascender }.fetch(baseline)
      end

      def placed((left, top))
        [ left, @top - top ]
      end

      def translucent(opacity, &painting)
        opacity < 1 ? @document.transparent(opacity, &painting) : yield
      end
    end
  end
end

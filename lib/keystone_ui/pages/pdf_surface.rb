# frozen_string_literal: true

require "prawn"

module KeystoneUi
  module Pages
    class PdfSurface
      BOLD_WEIGHT = 600
      MEASURING_HEIGHT = 14_400

      def initialize(look)
        @look = look
        @document = Prawn::Document.new
      end

      def text(content, size:, font: "--ks-font-body", weight: nil, color: "--ks-color-text", uppercase: false, tracking: nil, align: nil)
        content = content.to_s.upcase if uppercase
        points = @look.points(size)
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name, style: bold?(weight) ? :bold : :normal) do
          @document.character_spacing(tracking ? @look.points(tracking, size: points) : 0) { @document.text(content.to_s, size: points, align: align || :left) }
        end
      end

      def rich_text(runs, size:, font: "--ks-font-body", color: "--ks-color-text")
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name) { @document.formatted_text(runs.map { |run| { text: run[:text], link: run[:link], styles: %i[bold italic].select { |style| run[style] } }.compact }, size: @look.points(size)) }
      end

      def box(fill:, padding:, radius:, &content)
        inset = @look.points(padding.first) * padding.last
        width = @document.bounds.width
        top = @document.cursor
        height = measured(width - inset * 2, &content) + inset * 2
        @document.fill_color(@look.color(fill))
        @document.fill_rounded_rectangle([ 0, top ], width, height, @look.points(radius.first) * radius.last)
        @document.bounding_box([ inset, top - inset ], width: width - inset * 2, &content)
        @document.move_down(inset)
      end

      def rule(width:, color:)
        thickness = @look.points(width)
        @document.fill_color(@look.color(color))
        @document.fill_rectangle([ 0, @document.cursor ], @document.bounds.width, thickness)
        @document.move_down(thickness)
      end

      def space(token, steps)
        @document.move_down(@look.points(token) * steps)
      end

      def row(widths, gap: nil)
        spacing = gap ? @look.points(gap.first) * gap.last : 0
        top = @document.y
        lowest = top
        left = 0
        widths.each_with_index do |width, index|
          column_width = @document.bounds.width * width
          inset = index.positive? ? spacing : 0
          @document.y = top
          @document.bounding_box([ left + inset, @document.cursor ], width: column_width - inset) do
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

      def measured(width)
        drawing = @document
        @document = Prawn::Document.new(page_size: [ width, MEASURING_HEIGHT ], margin: 0)
        top = @document.cursor
        yield
        top - @document.cursor
      ensure
        @document = drawing
      end

      def bold?(weight)
        weight.present? && @look.weight(weight) >= BOLD_WEIGHT
      end
    end
  end
end

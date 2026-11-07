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

      def text(content, size:, font: "--ks-font-body", weight: nil, color: "--ks-color-text", uppercase: false, tracking: nil, align: nil, leading: nil)
        content = content.to_s.upcase if uppercase
        points = @look.points(size)
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name, style: bold?(weight) ? :bold : :normal) do
          @document.character_spacing(tracking ? @look.points(tracking, size: points) : 0) do
            spaced(points, leading) { |extra| @document.text(content.to_s, size: points, align: align || :left, leading: extra) }
          end
        end
      end

      def rich_text(runs, size:, font: "--ks-font-body", color: "--ks-color-text", leading: nil)
        points = @look.points(size)
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        fragments = runs.map { |run| { text: run[:text], link: run[:link], styles: %i[bold italic].select { |style| run[style] } }.compact }
        @document.font(typeface.name) { spaced(points, leading) { |extra| @document.formatted_text(fragments, size: points, leading: extra) } }
      end

      def box(padding:, radius:, fill: nil, border: nil, &content)
        inset = @look.points(padding.first) * padding.last
        width = @document.bounds.width
        top = @document.cursor
        height = measured(width - inset * 2, &content) + inset * 2
        corner = @look.points(radius.first) * radius.last
        if fill
          @document.fill_color(@look.color(fill))
          @document.fill_rounded_rectangle([ 0, top ], width, height, corner)
        end
        bordered(border, top, width, height, corner) if border
        @document.bounding_box([ inset, top - inset ], width: width - inset * 2, &content)
        @document.move_down(inset)
      end

      def boxed_text(content, size:, fill:, padding:, radius:, border: nil, link: nil, font: "--ks-font-body", weight: nil, color: "--ks-color-text", leading: nil)
        edge = border ? @look.points(border[:width]) : 0
        across = @look.points(padding.first) * padding[1] + edge
        down = @look.points(padding.first) * padding.last + edge
        width = @document.bounds.width
        top = @document.cursor
        drawn = -> { text(content, size: size, font: font, weight: weight, color: color, leading: leading) }
        height = measured(width - across * 2, &drawn) + down * 2
        fill_width = [ text_width(content, size, font, weight) + across * 2, width ].min
        linked(link, fill_width, height) if link
        @document.fill_color(@look.color(fill))
        @document.fill_rounded_rectangle([ 0, top ], fill_width, height, @look.points(radius.first) * radius.last)
        bordered(border, top, fill_width, height, @look.points(radius.first) * radius.last) if border
        @document.bounding_box([ across, top - down ], width: width - across * 2, &drawn)
        @document.move_down(down)
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

      def spaced(points, leading)
        extra = leading ? @look.ratio(leading) * points - @document.font.height_at(points) : 0
        @document.move_down(extra / 2)
        yield extra
        @document.move_down(extra / 2)
      end

      def measured(width)
        drawing = @document
        @document = Prawn::Document.new(page_size: [ width, MEASURING_HEIGHT ], margin: 0)
        top = @document.cursor
        yield
        top - @document.cursor
      ensure
        @document = drawing
      end

      def bordered(border, top, width, height, corner)
        thickness = @look.points(border[:width])
        return unless thickness.positive?

        @document.stroke_color(@look.color(border[:color]))
        @document.line_width(thickness)
        @document.stroke_rounded_rectangle([ thickness / 2, top - thickness / 2 ], width - thickness, height - thickness, corner)
      end

      def linked(address, width, height)
        left = @document.bounds.absolute_left
        top = @document.y
        @document.link_annotation([ left, top - height, left + width, top ], Border: [ 0, 0, 0 ], A: { Type: :Action, S: :URI, URI: PDF::Core::LiteralString.new(address) })
      end

      def text_width(content, size, font, weight)
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        width = 0
        @document.font(typeface.name, style: bold?(weight) ? :bold : :normal) { width = @document.width_of(content.to_s, size: @look.points(size)) }
        width
      end

      def bold?(weight)
        weight.present? && @look.weight(weight) >= BOLD_WEIGHT
      end
    end
  end
end

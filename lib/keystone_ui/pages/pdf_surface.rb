# frozen_string_literal: true

require "prawn"
require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    class PdfSurface
      class UndrawableCharacter < PrintFailed
        attr_reader :character

        def initialize(character)
          @character = character
          super(format("The PDF's font cannot draw the character %s (U+%04X).", character, character.ord))
        end
      end

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
          drawable!(content.to_s)
          @document.character_spacing(tracking ? @look.points(tracking, size: points) : 0) do
            spaced(points, leading) { |extra| @document.text(content.to_s, size: points, align: align || :left, leading: extra, final_gap: leading.nil?) }
          end
        end
      end

      def rich_text(runs, size:, font: "--ks-font-body", weight: nil, color: "--ks-color-text", leading: nil)
        points = @look.points(size)
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        fragments = runs.map { |run| fragment(bold?(weight) ? run.merge(bold: true) : run) }
        fragments.each { |fragment| @document.font(typeface.name, style: fragment[:styles].join("_").presence&.to_sym || :normal) { drawable!(fragment[:text].to_s) } }
        @document.font(typeface.name) { spaced(points, leading) { |extra| @document.formatted_text(fragments, size: points, leading: extra, final_gap: leading.nil?) } }
      end

      def box(padding:, radius:, fill: nil, border: nil, &content)
        across, down = insets(padding, border)
        width = @document.bounds.width
        top = @document.cursor
        height = measured(width - across * 2, &content) + down * 2
        corner = @look.points(radius.first) * radius.last
        if fill
          @document.fill_color(@look.color(fill))
          @document.fill_rounded_rectangle([ 0, top ], width, height, corner)
        end
        bordered(border, top, width, height, corner) if border
        @document.bounding_box([ across, top - down ], width: width - across * 2, &content)
        @document.move_down(down)
      end

      def boxed_text(content, size:, fill:, padding:, radius:, border: nil, link: nil, font: "--ks-font-body", weight: nil, color: "--ks-color-text", leading: nil)
        across, down = insets(padding, border)
        width = @document.bounds.width
        top = @document.cursor
        drawn = -> { text(content, size: size, font: font, weight: weight, color: color, leading: leading) }
        height = measured(width - across * 2, &drawn) + down * 2
        fill_width = [ text_width(content, size, font, weight) + across * 2, width ].min
        corner = corner(radius, fill_width, height)
        linked(link, fill_width, height) if link
        @document.fill_color(@look.color(fill))
        @document.fill_rounded_rectangle([ 0, top ], fill_width, height, corner)
        bordered(border, top, fill_width, height, corner) if border
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
        first_page = @document.page_number
        lowest = [ first_page, -top ]
        left = 0
        widths.each_with_index do |width, index|
          column_width = @document.bounds.width * width
          inset = index.positive? ? spacing : 0
          @document.go_to_page(first_page)
          @document.y = top
          @document.bounding_box([ left + inset, @document.cursor ], width: column_width - inset) do
            yield index
            lowest = [ lowest, [ @document.page_number, -@document.y ] ].max
          end
          left += column_width
        end
        @document.go_to_page(lowest.first)
        @document.y = -lowest.last
      end

      def table(heading, rows, border:, radius:, divider:, total: nil, parts_divider: nil)
        edge = @look.points(border[:width])
        frame = { border: border, edge: edge, corner: @look.points(radius.first) * radius.last, left: @document.bounds.absolute_left, width: @document.bounds.width, top: @document.y }
        @document.move_down(edge)
        @document.bounding_box([ edge, @document.cursor ], width: @document.bounds.width - edge * 2) do
          below = [ *rows, total ].compact
          widths = column_widths([ heading, *below ])
          separators = below.each_index.map { |position| position == rows.size ? parts_divider : (divider if position.positive?) }
          heading_lines = { row: heading, line: parts_divider }
          restarted(frame) unless fits?(headed_height(heading_lines, widths) + rows_height(kept_together(below, 0), widths))
          headed(heading_lines, widths, frame, below.empty?)
          below.each_with_index do |table_row, position|
            kept_on_page(kept_together(below, position), separators[position], heading_lines, widths, frame) { divided(separators[position], widths.sum) }
            following = line_thickness(separators[position + 1]) + rows_height(kept_together(below, position + 1), widths)
            closing = position == below.size - 1 || !fits?(row_height(table_row, widths) + following)
            drawn_table_row(table_row, widths, frame, closing)
          end
          framed(frame)
        end
      end

      def render
        @document.render
      end

      private

      def fragment(run)
        { text: run[:text], link: run[:link], size: run[:size] && @look.points(run[:size]), color: run[:color] && @look.color(run[:color]),
          styles: %i[bold italic].select { |style| run[style] } }.compact
      end

      def column_widths(table_rows)
        room = @document.bounds.width
        widest = cell_widths(table_rows) { |cell| padded_width(cell, cell[:text].to_s) }
        return widest.map { |width| room * width / widest.sum } if widest.sum <= room

        narrowest = cell_widths(table_rows) { |cell| cell[:text].to_s.split.map { |word| padded_width(cell, word) }.max.to_f }
        kept = kept_columns(widest, room)
        wrapped = widest.each_index.to_a - kept
        shared = wrapped_widths(widest.values_at(*wrapped), narrowest.values_at(*wrapped), room - widest.values_at(*kept).sum)
        widest.each_index.map { |index| kept.include?(index) ? widest[index] : shared[wrapped.index(index)] }
      end

      def kept_columns(widest, room)
        kept = []
        loop do
          wrapped = widest.each_index.to_a - kept
          share = (room - widest.values_at(*kept).sum) / wrapped.size
          fitting = wrapped.select { |index| widest[index] <= share }
          return kept if fitting.empty?

          kept += fitting
        end
      end

      def wrapped_widths(widest, narrowest, room)
        return narrowest.map { |width| room * width / narrowest.sum } if narrowest.sum >= room

        spare = widest.zip(narrowest).map { |most, least| most - least }
        narrowest.zip(spare).map { |least, extra| least + (room - narrowest.sum) * extra / spare.sum }
      end

      def cell_widths(table_rows, &measure)
        table_rows.map { |table_row| table_row[:cells].map(&measure) }.transpose.map(&:max)
      end

      def padded_width(cell, content)
        left, right = cell_insets(cell)
        text_width(content, cell[:size], cell[:font] || "--ks-font-body", cell[:weight]) + left + right
      end

      def drawn_table_row(table_row, widths, frame, closing)
        top = @document.y
        height = row_height(table_row, widths)
        filled(table_row[:fill], widths.sum, height, frame, closing) if table_row[:fill]
        table_row[:cells].each_with_index do |cell, index|
          left, right, down = cell_insets(cell)
          @document.y = top - (height - cell_height(cell, widths[index])) / 2 - down
          @document.bounding_box([ widths.take(index).sum + left, @document.cursor ], width: widths[index] - left - right) { drawn_cell(cell) }
        end
        @document.y = top - height
      end

      def filled(fill, width, height, frame, closing)
        inside_top = frame[:top] - frame[:edge]
        inside_bottom = @document.y - height - (closing ? 0 : frame[:corner])
        @document.save_graphics_state do
          @document.rounded_rectangle([ 0, inside_top - @document.bounds.absolute_bottom ], width, inside_top - inside_bottom, [ frame[:corner] - frame[:edge], 0 ].max)
          @document.add_content("W n")
          @document.fill_color(@look.color(fill))
          @document.fill_rectangle([ 0, @document.cursor ], width, height)
        end
      end

      def kept_together(rows, position)
        rows[position]&.dig(:with_next) ? rows[position, 2] : rows[position, 1]
      end

      def kept_on_page(table_rows, separator, heading_lines, widths, frame)
        return yield if fits?(line_thickness(separator) + rows_height(table_rows, widths))

        framed(frame)
        restarted(frame)
        headed(heading_lines, widths, frame, false)
      end

      def headed(heading_lines, widths, frame, closing)
        drawn_table_row(heading_lines[:row], widths, frame, closing)
        divided(heading_lines[:line], widths.sum)
      end

      def headed_height(heading_lines, widths)
        row_height(heading_lines[:row], widths) + line_thickness(heading_lines[:line])
      end

      def rows_height(table_rows, widths)
        table_rows.sum { |table_row| row_height(table_row, widths) }
      end

      def line_thickness(line)
        line ? @look.points(line[:width]) : 0
      end

      def restarted(frame)
        next_page
        frame[:top] = @document.y
        @document.move_down(frame[:edge])
      end

      def fits?(height)
        @document.y - height >= @document.margin_box.absolute_bottom
      end

      def framed(frame)
        @document.move_down(frame[:edge])
        top = frame[:top] - @document.bounds.absolute_bottom
        bordered(frame[:border], top, frame[:width], frame[:top] - @document.y, frame[:corner], frame[:left] - @document.bounds.absolute_left)
      end

      def next_page
        @document.bounds.move_past_bottom
        @document.y = @document.margin_box.absolute_top
      end

      def divided(divider, width)
        return unless divider

        thickness = @look.points(divider[:width])
        @document.fill_color(@look.color(divider[:color]))
        @document.fill_rectangle([ 0, @document.cursor ], width, thickness)
        @document.move_down(thickness)
      end

      def row_height(table_row, widths)
        table_row[:cells].each_with_index.map { |cell, index| cell_height(cell, widths[index]) }.max
      end

      def cell_height(cell, width)
        left, right, down = cell_insets(cell)
        measured(width - left - right) { drawn_cell(cell) } + down * 2
      end

      def drawn_cell(cell)
        text(cell[:text], **cell.except(:text, :padding))
      end

      def cell_insets(cell)
        token, *steps = cell[:padding]
        steps.map { |step| @look.points(token) * step }
      end

      def drawable!(content)
        missing = content.each_char.find { |char| !char.match?(/[[:cntrl:]]/) && !@document.font.glyph_present?(char) }
        raise UndrawableCharacter, missing if missing
      end

      def spaced(points, leading)
        return yield 0 unless leading

        line = @look.ratio(leading) * points
        font = @document.font
        letters = (font.ascender + font.descender) / @document.font_size * points
        extra = line - font.height_at(points)
        @document.move_down((line - letters) / 2)
        yield extra
        @document.move_down((line - letters) / 2)
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

      def corner(radius, width, height)
        [ @look.points(radius.first) * radius.last, width / 2, height / 2 ].min
      end

      def insets(padding, border)
        edge = border ? @look.points(border[:width]) : 0
        [ @look.points(padding.first) * padding[1] + edge, @look.points(padding.first) * padding.last + edge ]
      end

      def bordered(border, top, width, height, corner, left = 0)
        thickness = @look.points(border[:width])
        return unless thickness.positive?

        @document.stroke_color(@look.color(border[:color]))
        @document.line_width(thickness)
        @document.stroke_rounded_rectangle([ left + thickness / 2, top - thickness / 2 ], width - thickness, height - thickness, corner)
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
        @document.font(typeface.name, style: bold?(weight) ? :bold : :normal) do
          drawable!(content.to_s)
          width = @document.width_of(content.to_s, size: @look.points(size))
        end
        width
      end

      def bold?(weight)
        weight.present? && @look.weight(weight) >= BOLD_WEIGHT
      end
    end
  end
end

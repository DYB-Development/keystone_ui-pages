# frozen_string_literal: true

require "prawn"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/pdf_plot"

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
      COLUMN_PLACES = { top: 0, center: Rational(1, 2), bottom: 1 }.freeze
      WRAP_ROUNDING = 1 + Float::EPSILON * 64
      ALIGNED_PLACES = { start: 0, center: Rational(1, 2), end: 1 }.freeze
      MEASURING_HEIGHT = 14_400
      NO_BREAK_SPACE = "\u00A0"
      TAB_SIZE = "tab-size"

      def initialize(look)
        @look = look
        @document = Prawn::Document.new
      end

      def text(content, size:, font: "--ks-font-body", weight: nil, color: "--ks-color-text", uppercase: false, tracking: nil, align: nil, leading: nil, preformatted: false)
        content = content.to_s.upcase if uppercase
        content = kept_spaces(content.to_s) if preformatted
        points = @look.points(size)
        typeface = @look.font(font)
        @document.font_families[typeface.name] = typeface.files if typeface.files
        @document.fill_color(@look.color(color))
        @document.font(typeface.name, style: bold?(weight) ? :bold : :normal) do
          drawable!(content.to_s)
          @document.character_spacing(tracking ? @look.points(tracking, size: points) : 0) do
            reached(content.to_s.lines.map { |line| @document.width_of(line.chomp, size: points) }.max.to_f) if @reached
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
        fragments.each { |fragment| @document.font(typeface.name, style: fragment_style(fragment)) { drawable!(fragment[:text].to_s) } }
        reached(runs_width(fragments, typeface, points)) if @reached
        @document.font(typeface.name) { spaced(points, leading) { |extra| @document.formatted_text(fragments, size: points, leading: extra, final_gap: leading.nil?) } }
      end

      def box(padding:, width: nil, align: nil, radius: nil, fill: nil, border: nil, clip: false, stretch: false, &content)
        across, down = insets(padding, border)
        fixed = width
        width = width ? [ @look.points(width.first) * width.last, @document.bounds.width ].min : @document.bounds.width
        left = align == :center ? (@document.bounds.width - width) / 2 : 0
        reached(fixed ? width : reach(width - across * 2, &content) + across * 2, left) if @reached
        height = measured(width - across * 2, &content) + down * 2
        height = [ height, @stretched.to_f ].max if stretch
        next_page unless fits?(height) || height > @document.margin_box.height
        top = @document.cursor
        bottom = @document.bounds.absolute_bottom
        corner = radius ? @look.points(radius.first) * radius.last : 0
        if fill
          @document.fill_color(@look.color(fill))
          @document.fill_rounded_rectangle([ left, top ], width, height, corner)
        end
        bordered(border, top, width, height, corner, left) if border && !clip
        clipped(clip && [ left, top, width, height, corner, border ]) { @document.bounding_box([ left + across, top - down ], width: width - across * 2, &content) }
        bordered(border, top + bottom - @document.bounds.absolute_bottom, width, height, corner, left) if border && clip
        @document.move_down(down)
        @document.y = bottom + top - height if stretch
      end

      def boxed_text(content, size:, fill:, padding:, radius:, border: nil, link: nil, font: "--ks-font-body", weight: nil, color: "--ks-color-text", leading: nil, align: nil)
        across, down = insets(padding, border)
        width = @document.bounds.width
        top = @document.cursor
        drawn = -> { text(content, size: size, font: font, weight: weight, color: color, leading: leading) }
        height = measured(width - across * 2, &drawn) + down * 2
        fill_width = [ text_width(content, size, font, weight) + across * 2, width ].min
        left = align == :center ? (width - fill_width) / 2 : 0
        return reached(fill_width, left) if @reached

        corner = corner(radius, fill_width, height)
        linked(link, fill_width, height, left) if link
        translucent(fill) do
          @document.fill_color(@look.color(fill))
          @document.fill_rounded_rectangle([ left, top ], fill_width, height, corner)
        end
        bordered(border, top, fill_width, height, corner, left) if border
        @document.bounding_box([ left + across, top - down ], width: width - left - across * 2, &drawn)
        @document.move_down(down)
      end

      def aligned(align, &content)
        width = [ reach(@document.bounds.width, &content) * WRAP_ROUNDING, @document.bounds.width ].min
        return yield unless width.positive?

        @document.bounding_box([ (@document.bounds.width - width) * ALIGNED_PLACES.fetch(align), @document.cursor ], width: width, &content)
      end

      def together(&content)
        height = measured(@document.bounds.width, &content)
        next_page unless fits?(height) || height > @document.margin_box.height
        yield
      end

      def bar(share, height:, radius:, track:, fill:)
        thickness = @look.points(height.first) * height.last
        width = @document.bounds.width
        top = @document.cursor
        [ [ track, width ], [ fill, width * share ] ].select { |_color, length| length.positive? }.each do |color, length|
          @document.fill_color(@look.color(color))
          @document.fill_rounded_rectangle([ 0, top ], length, thickness, corner(radius, length, thickness))
        end
        @document.move_down(thickness)
      end

      def plot(height:)
        width = @document.bounds.width
        return reached(width) if @reached

        tall = @look.points(height.first) * height.last
        next_page unless fits?(tall)
        yield PdfPlot.new(@document, @look, width, tall)
        @document.move_down(tall)
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

      def row(widths, gap: nil, grid: false, align: [])
        reached(@document.bounds.width) if @reached
        spacing = gap ? @look.points(gap.first) * gap.last : 0
        room = grid ? @document.bounds.width + spacing : @document.bounds.width
        lost = grid ? spacing : 0
        heights = widths.each_with_index.map { |width, index| measured(room * width - lost) { yield index } } if grid
        stretched = heights&.max
        top = @document.y
        first_page = @document.page_number
        lowest = [ first_page, -top ]
        left = 0
        widths.each_with_index do |width, index|
          column_width = room * width - lost
          inset = index.positive? && !grid ? spacing : 0
          @document.go_to_page(first_page)
          @document.y = top - (heights ? (stretched - heights[index]) * COLUMN_PLACES.fetch(align[index] || :top) : 0)
          @document.bounding_box([ left + inset, @document.cursor ], width: column_width - inset) do
            @stretched = stretched
            yield index
            @stretched = nil
            lowest = [ lowest, [ @document.page_number, -@document.y ] ].max
          end
          left += column_width + (grid ? spacing : 0)
        end
        @document.go_to_page(lowest.first)
        @document.y = -lowest.last
      end

      def table(heading, rows, border:, radius:, divider:, total: nil, parts_divider: nil)
        return reached(@document.bounds.width) if @reached

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

      def fragment_style(fragment)
        fragment[:styles].join("_").presence&.to_sym || :normal
      end

      def runs_width(fragments, typeface, points)
        lines = [ 0 ]
        fragments.each do |fragment|
          @document.font(typeface.name, style: fragment_style(fragment)) do
            fragment[:text].to_s.split("\n", -1).each_with_index do |piece, index|
              lines << 0 if index.positive?
              lines[-1] += @document.width_of(piece, size: fragment[:size] || points)
            end
          end
        end
        lines.max
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

      def reach(width)
        outer = @reached
        @reached = 0
        measured(width) { yield }
        @reached
      ensure
        @reached = outer
      end

      def reached(width, left = 0)
        @reached = [ @reached, @document.bounds.absolute_left + left + [ width, @document.bounds.width - left ].min ].max
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

        translucent(border[:color]) do
          @document.stroke_color(@look.color(border[:color]))
          @document.line_width(thickness)
          @document.stroke_rounded_rectangle([ left + thickness / 2, top - thickness / 2 ], width - thickness, height - thickness, corner)
        end
      end

      def linked(address, width, height, offset = 0)
        left = @document.bounds.absolute_left + offset
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

      def clipped(shape)
        return yield unless shape

        left, top, width, height, corner, border = shape
        edge = border ? @look.points(border[:width]) : 0
        @document.save_graphics_state do
          @document.rounded_rectangle([ left + edge, top - edge ], width - edge * 2, height - edge * 2, [ corner - edge, 0 ].max)
          @document.add_content("W n")
          yield
        end
      end

      def kept_spaces(content)
        content.lines.map { |line| tab_stopped(line) }.join.gsub(/^ +/) { |spaces| NO_BREAK_SPACE * spaces.length }
      end

      def tab_stopped(line)
        return line unless line.include?("\t")

        stop = @look.value(TAB_SIZE).to_i
        line.each_char.with_object(+"") { |char, spaced| spaced << (char == "\t" ? " " * (stop - spaced.length % stop) : char) }
      end

      def translucent(color, &painting)
        opacity = @look.opacity(color)
        opacity < 1 ? @document.transparent(opacity, &painting) : yield
      end

      def bold?(weight)
        weight.present? && @look.weight(weight) >= BOLD_WEIGHT
      end
    end
  end
end

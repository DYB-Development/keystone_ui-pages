# frozen_string_literal: true

require "keystone_ui/pages/pdf_line_ticks"

module KeystoneUi
  module Pages
    module PdfCharts
      TAILWIND_SPACING = "--spacing"
      FULL = 100.0
      BAR_CHART_HEIGHT = [ TAILWIND_SPACING, 80 ].freeze
      BAR_CHART_RATIO = Rational(2, 5)
      BAR_CHART_AXIS_WIDTH = 10
      BAR_CHART_LABEL_HEIGHT = 6
      BAR_LOOK = { color: "--ks-color-chart-1" }.freeze
      SHADED_BAR_CLASS = "ks-bar-chart-bar-shaded"
      SHADED_BAR_LOOK = BAR_LOOK.merge(opacity: 0.4).freeze
      BAR_LABEL_RISE = "6px"
      TICK_GAP = "6px"
      GRID_LINE = { width: "1px", color: "--ks-color-border" }.freeze
      CHART_TEXT = { size: "--text-xs", color: "--ks-color-text-muted" }.freeze
      VALUE_TEXT = { size: "--text-xs", color: "--ks-color-text", anchor: :middle }.freeze
      VALUE_RISE = "4px"
      LINE_CHART_HEIGHT = [ TAILWIND_SPACING, 64 ].freeze
      LINE_WIDTH = "1.5px"
      DASH = "6px"
      VARIABLE = /\Avar\((--[^)]+)\)\z/
      SERIES_COLORS = Array.new(5) { |index| "--ks-color-chart-#{index + 1}" }.freeze
      AXIS_SIZE = "11px"
      CHART_LINE_HEIGHT = 1.2
      AXIS_TEXT = { size: AXIS_SIZE, color: "--ks-color-text-muted" }.freeze
      TICK_LENGTH = "8px"
      TICK_PADDING = "3px"
      AXIS_BORDER = { width: "1px", color: "#0000001A" }.freeze
      LEGEND_SIZE = "12px"
      LEGEND_FONT = "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif"
      LEGEND_BOX_WIDTH = "40px"
      LEGEND_PADDING = "10px"
      LEGEND_COLOR = "#666"
      LEGEND_FILL = "#0000001A"

      module_function

      def bar_chart(surface, fields)
        chart = Keystone::Ui::BarChartComponent.new(bars: entries(fields[:bars]), show_values: fields[:show_values].to_s == "true")
        surface.plot(height: BAR_CHART_HEIGHT, ratio: BAR_CHART_RATIO) do |plot|
          area = bar_chart_area(plot)
          chart.ticks.each { |tick| plot.line([ placed(area, 0, tick[:y]), placed(area, FULL, tick[:y]) ], **GRID_LINE) }
          chart.ticks.each { |tick| plot.label(tick[:label], area[:left] - plot.points(TICK_GAP), placed(area, 0, tick[:y]).last, **CHART_TEXT, anchor: :end, baseline: :middle) }
          chart.drawn_bars.each { |bar| plot.rect(*placed(area, bar[:x], bar[:y]), *sized(area, bar[:width], bar[:height]), **bar_look(bar)) }
          chart.drawn_bars.each { |bar| bar_value(plot, area, bar) } if chart.show_values?
          chart.drawn_bars.each { |bar| plot.label(bar[:label], placed(area, bar[:center], 0).first, plot.height - plot.points(BAR_LABEL_RISE), **CHART_TEXT, anchor: :middle) }
        end
      end

      def line_chart(surface, fields)
        series = entries(fields[:series])
        labels = Array(fields[:labels].presence).map(&:to_s)
        surface.plot(height: LINE_CHART_HEIGHT) do |plot|
          colors = series_colors(series)
          area = line_chart_area(plot, series, labels)
          legend(plot, series, colors)
          line_chart_ticks(plot, area)
          line_chart_labels(plot, area, labels)
          plot.line([ [ area[:left], area[:bottom] ], [ area[:right], area[:bottom] ] ], **AXIS_BORDER)
          series.zip(colors).each { |entry, color| series_lines(plot, area, labels, entry, color) }
        end
      end

      def line_chart_area(plot, series, labels)
        top = legend_height(plot, series)
        bottom = plot.height - plot.points(TICK_LENGTH) - plot.points(TICK_PADDING) - axis_line(plot)
        ticks = PdfLineTicks.new(series.flat_map { |entry| numbers(entry[:data]) }.compact, (bottom - top) / axis_line(plot))
        left = [ plot.points(TICK_LENGTH) + plot.points(TICK_PADDING) + ticks.labels.map { |label| axis_width(plot, label) }.max, axis_width(plot, labels.first) / 2 ].max
        { left: left, right: plot.width - axis_width(plot, labels.last) / 2, top: top, bottom: bottom, ticks: ticks }
      end

      def line_chart_ticks(plot, area)
        ticks = area[:ticks]
        ticks.values.each { |value| plot.line([ [ area[:left] - plot.points(TICK_LENGTH), down(area, value) ], [ area[:right], down(area, value) ] ], **GRID_LINE) }
        ticks.values.zip(ticks.labels).each do |value, label|
          plot.label(label, area[:left] - plot.points(TICK_LENGTH) - plot.points(TICK_PADDING), down(area, value), **AXIS_TEXT, anchor: :end, baseline: :middle)
        end
      end

      def line_chart_labels(plot, area, labels)
        down = area[:bottom] + plot.points(TICK_LENGTH) + plot.points(TICK_PADDING) + axis_line(plot) / 2
        labels.each_with_index { |label, index| plot.label(label, across(area, index, labels.size), down, **AXIS_TEXT, anchor: :middle, baseline: :middle) }
      end

      def series_colors(series)
        uncolored = -1
        series.map { |entry| entry[:color].present? ? own_color(entry[:color].to_s) : SERIES_COLORS[(uncolored += 1) % SERIES_COLORS.size] }
      end

      def own_color(color)
        color[VARIABLE, 1] || color
      end

      def series_lines(plot, area, labels, entry, color)
        numbers(entry[:data]).first(labels.size).each_with_index.map { |value, index| value && [ across(area, index, labels.size), down(area, value) ] }
                             .chunk_while { |point, following| point && following }.select { |points| points.compact.size > 1 }
                             .each { |points| plot.line(points, width: LINE_WIDTH, color: color, dash: dash(entry)) }
      end

      def across(area, index, count)
        area[:left] + (count > 1 ? index.to_f / (count - 1) : 0) * (area[:right] - area[:left])
      end

      def down(area, value)
        ticks = area[:ticks]
        area[:top] + (ticks.most - value) / (ticks.most - ticks.least) * (area[:bottom] - area[:top])
      end

      def numbers(data)
        Array(data).map { |value| value.nil? ? nil : Float(value, exception: false) }
      end

      def axis_line(plot)
        plot.points(AXIS_SIZE) * CHART_LINE_HEIGHT
      end

      def axis_width(plot, text)
        text.nil? ? 0 : plot.text_width(text, size: AXIS_SIZE)
      end

      def dash(entry)
        DASH if entry[:dashed]
      end

      def legend(plot, series, colors)
        padding = plot.points(LEGEND_PADDING)
        legend_rows(plot, series).each_with_index do |row, position|
          left = (padding + plot.width - row.sum { |item| item[:width] + padding }) / 2
          top = padding + position * (plot.points(LEGEND_SIZE) + padding)
          row.each do |item|
            legend_item(plot, item[:entry], colors[item[:index]], left, top)
            left += item[:width] + padding
          end
        end
      end

      def legend_item(plot, entry, color, left, top)
        box = plot.points(LEGEND_BOX_WIDTH)
        tall = plot.points(LEGEND_SIZE)
        plot.rect(left, top, box, tall, color: LEGEND_FILL)
        plot.line([ [ left, top ], [ left + box, top ], [ left + box, top + tall ], [ left, top + tall ], [ left, top ] ], width: LINE_WIDTH, color: color, dash: dash(entry))
        plot.label(entry[:name].to_s, left + box + tall / 2, top + tall / 2, size: LEGEND_SIZE, color: LEGEND_COLOR, font: LEGEND_FONT, baseline: :middle)
      end

      def legend_height(plot, series)
        padding = plot.points(LEGEND_PADDING)
        legend_rows(plot, series).size * (plot.points(LEGEND_SIZE) + padding) + padding
      end

      def legend_rows(plot, series)
        padding = plot.points(LEGEND_PADDING)
        series.each_with_index.each_with_object([]) do |(entry, index), rows|
          width = legend_item_width(plot, entry)
          rows << [] if rows.empty? || rows.last.sum { |item| item[:width] + padding } + width + padding * 2 > plot.width
          rows.last << { entry: entry, index: index, width: width }
        end
      end

      def legend_item_width(plot, entry)
        plot.points(LEGEND_BOX_WIDTH) + plot.points(LEGEND_SIZE) / 2 + plot.text_width(entry[:name].to_s, size: LEGEND_SIZE, font: LEGEND_FONT)
      end

      def bar_value(plot, area, bar)
        across, down = placed(area, bar[:center], bar[:y])
        plot.label(bar[:value], across, down - plot.points(VALUE_RISE), **VALUE_TEXT)
      end

      def bar_look(bar)
        bar[:classes].split.include?(SHADED_BAR_CLASS) ? SHADED_BAR_LOOK : BAR_LOOK
      end

      def bar_chart_area(plot)
        left = plot.points(TAILWIND_SPACING) * BAR_CHART_AXIS_WIDTH
        { left: left, width: plot.width - left, height: plot.height - plot.points(TAILWIND_SPACING) * BAR_CHART_LABEL_HEIGHT }
      end

      def placed(area, across, down)
        [ area[:left] + area[:width] * across / FULL, area[:height] * down / FULL ]
      end

      def sized(area, across, down)
        [ area[:width] * across / FULL, area[:height] * down / FULL ]
      end

      def entries(given)
        Array(given).select { |entry| entry.is_a?(Hash) }.map(&:symbolize_keys)
      end
    end
  end
end

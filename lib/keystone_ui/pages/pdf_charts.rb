# frozen_string_literal: true

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

      module_function

      def bar_chart(surface, fields)
        chart = Keystone::Ui::BarChartComponent.new(bars: entries(fields[:bars]), show_values: fields[:show_values].to_s == "true")
        surface.plot(height: BAR_CHART_HEIGHT, ratio: BAR_CHART_RATIO) do |plot|
          area = bar_chart_area(plot)
          chart.ticks.each { |tick| plot.line([ placed(area, 0, tick[:y]), placed(area, FULL, tick[:y]) ], **GRID_LINE) }
          chart.ticks.each { |tick| plot.label(tick[:label], area[:left] - plot.points(TICK_GAP), placed(area, 0, tick[:y]).last, **CHART_TEXT, anchor: :end, baseline: :middle) }
          chart.drawn_bars.each { |bar| plot.rect(*placed(area, bar[:x], bar[:y]), *sized(area, bar[:width], bar[:height]), **bar_look(bar)) }
          chart.drawn_bars.each { |bar| plot.label(bar[:label], placed(area, bar[:center], 0).first, plot.height - plot.points(BAR_LABEL_RISE), **CHART_TEXT, anchor: :middle) }
        end
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

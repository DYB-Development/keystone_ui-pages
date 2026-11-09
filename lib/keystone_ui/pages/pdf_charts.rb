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
      BAR_COLOR = "--ks-color-chart-1"
      BAR_LABEL_RISE = "6px"
      CHART_TEXT = { size: "--text-xs", color: "--ks-color-text-muted" }.freeze

      module_function

      def bar_chart(surface, fields)
        chart = Keystone::Ui::BarChartComponent.new(bars: entries(fields[:bars]), show_values: fields[:show_values].to_s == "true")
        surface.plot(height: BAR_CHART_HEIGHT, ratio: BAR_CHART_RATIO) do |plot|
          area = bar_chart_area(plot)
          chart.drawn_bars.each { |bar| plot.rect(*placed(area, bar[:x], bar[:y]), *sized(area, bar[:width], bar[:height]), color: BAR_COLOR) }
          chart.drawn_bars.each { |bar| plot.label(bar[:label], placed(area, bar[:center], 0).first, plot.height - plot.points(BAR_LABEL_RISE), **CHART_TEXT, anchor: :middle) }
        end
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

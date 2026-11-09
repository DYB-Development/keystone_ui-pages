# frozen_string_literal: true

require "active_support/number_helper"

module KeystoneUi
  module Pages
    class PdfLineTicks
      MOST = 11
      SMALLEST_SPACING = 1e-14
      EMPTY_RANGE = [ 0.0, 1.0 ].freeze
      FLAT_SHARE = 0.05
      MOST_DECIMALS = 20

      attr_reader :values

      def initialize(data, room)
        least, most = range(data)
        @values = generated(least, most, [ [ MOST, room.ceil ].min, 2 ].max)
      end

      def least
        values.first
      end

      def most
        values.last
      end

      def labels
        values.map { |value| label(value) }
      end

      private

      def range(data)
        return EMPTY_RANGE if data.empty?

        least, most = data.minmax
        return [ least, most ] unless least == most

        offset = most.zero? ? 1 : (most * FLAT_SHARE).abs
        [ least - offset, most + offset ]
      end

      def generated(least, most, count)
        spaces = count - 1
        spacing = nice((most - least) / spaces)
        return [ least, most ] if spacing < SMALLEST_SPACING

        steps = (most / spacing).ceil - (least / spacing).floor
        spacing = nice(steps * spacing / spaces) if steps > spaces
        low = (least / spacing).floor * spacing
        high = (most / spacing).ceil * spacing
        steps = (high - low) / spacing
        steps = almost?(steps, steps.round, spacing / 1000) ? steps.round : steps.ceil
        factor = 10.0**[ decimals(spacing), decimals(low) ].max
        low = (low * factor).round / factor
        Array.new(steps) { |step| ((low + step * spacing) * factor).round / factor } + [ (high * factor).round / factor ]
      end

      def nice(range)
        range = range.round.to_f if almost?(range, range.round, range / 1000)
        magnitude = 10.0**Math.log10(range).floor
        fraction = range / magnitude
        [ 1, 2, 5 ].find { |nice_fraction| fraction <= nice_fraction }.then { |nice_fraction| (nice_fraction || 10) * magnitude }
      end

      def almost?(value, target, margin)
        (value - target).abs < margin
      end

      def decimals(value)
        places = 0
        places += 1 until (value * 10**places).round.to_f / 10**places == value || places > MOST_DECIMALS
        places
      end

      def label(value)
        return "0" if value.zero?

        places = Math.log10(delta(value).abs).then { |power| power.finite? ? (-power.floor).clamp(0, MOST_DECIMALS) : 1 }
        ActiveSupport::NumberHelper.number_to_delimited(format("%.#{places}f", value))
      end

      def delta(value)
        return value if values.size < 2

        step = values.size > 3 ? values[2] - values[1] : values[1] - values[0]
        step.abs >= 1 && value != value.floor ? value - value.floor : step
      end
    end
  end
end

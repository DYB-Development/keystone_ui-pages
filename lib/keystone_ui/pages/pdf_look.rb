# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfLook
      OKLAB_TO_LMS = [ [ 0.3963377774, 0.2158037573 ], [ -0.1055613458, -0.0638541728 ], [ -0.0894841775, -1.2914855480 ] ].freeze
      LMS_TO_SRGB = [ [ 4.0767416621, -3.3077115913, 0.2309699292 ], [ -1.2684380046, 2.6097574011, -0.3413193965 ], [ -0.0041960863, -0.7034186147, 1.7076147010 ] ].freeze

      def initialize(stylesheet)
        @values = stylesheet.scan(/\{([^{}]*)\}/).flatten.flat_map { |block| block.split(";") }.to_h { |declaration| declaration.split(":", 2).map(&:strip) }
      end

      def color(name)
        css = value(name)
        return oklch_hex(css) if css.start_with?("oklch(")

        css.delete_prefix("#").upcase
      end

      def value(name)
        @values.fetch(name).gsub(/var\((--[\w-]+)\)/) { value(Regexp.last_match(1)) }
      end

      private

      def oklch_hex(css)
        lightness, chroma, hue = css[/\((.*)\)/, 1].split
        lightness = lightness.end_with?("%") ? lightness.to_f / 100 : lightness.to_f
        a = chroma.to_f * Math.cos(hue.to_f * Math::PI / 180)
        b = chroma.to_f * Math.sin(hue.to_f * Math::PI / 180)
        lms = OKLAB_TO_LMS.map { |(from_a, from_b)| (lightness + from_a * a + from_b * b)**3 }
        LMS_TO_SRGB.map { |row| format("%02X", (gamma(row.zip(lms).sum { |factor, part| factor * part }) * 255).round) }.join
      end

      def gamma(linear)
        linear = linear.clamp(0.0, 1.0)
        linear <= 0.0031308 ? 12.92 * linear : 1.055 * linear**(1 / 2.4) - 0.055
      end
    end
  end
end

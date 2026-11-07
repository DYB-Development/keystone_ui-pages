# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfLook
      OKLAB_TO_LMS = [ [ 0.3963377774, 0.2158037573 ], [ -0.1055613458, -0.0638541728 ], [ -0.0894841775, -1.2914855480 ] ].freeze
      ROOTS = [ ":root", ":host", "html" ].freeze
      LMS_TO_SRGB = [ [ 4.0767416621, -3.3077115913, 0.2309699292 ], [ -1.2684380046, 2.6097574011, -0.3413193965 ], [ -0.0041960863, -0.7034186147, 1.7076147010 ] ].freeze

      def initialize(stylesheet, look: nil)
        @look = look
        @values = declarations(stylesheet).sort_by.with_index { |(rank, _declaration), index| [ rank, index ] }.to_h { |_rank, declaration| declaration }
      end

      def color(name)
        css = value(name)
        return oklch_hex(css) if css.start_with?("oklch(")

        css.delete_prefix("#").upcase
      end

      def value(name)
        resolved(@values.fetch(name))
      end

      private

      def resolved(css)
        start = css.index("var(")
        return css unless start

        finish = closing(css, start + 3)
        variable, fallback = css[(start + 4)...finish].split(",", 2).map(&:strip)
        replacement = @values.key?(variable) ? value(variable) : resolved(fallback.to_s)
        resolved(css[0...start] + replacement + css[(finish + 1)..])
      end

      def closing(css, opening)
        depth = 0
        (opening...css.length).find do |index|
          depth += { "(" => 1, ")" => -1 }.fetch(css[index], 0)
          depth.zero?
        end
      end

      def declarations(stylesheet)
        rules(stylesheet).flat_map do |preludes, body|
          selectors = split(preludes.last.to_s, ",").map(&:strip)
          next [] if preludes.any? { |prelude| prelude.start_with?("@") && !prelude.start_with?("@layer") }
          next [] unless selectors.any? { |selector| ROOTS.include?(selector) || looked?(selector) }

          rank = [ preludes.any? { |prelude| prelude.start_with?("@layer") } ? 0 : 1, selectors.any? { |selector| looked?(selector) } ? 1 : 0 ]
          split(body, ";").filter_map { |declaration| [ rank, declaration.split(":", 2).map(&:strip) ] if declaration.include?(":") }
        end
      end

      def looked?(selector)
        @look.present? && selector.match?(/\A(?::root|html)?\[data-look=["']?#{Regexp.escape(@look)}["']?\]\z/)
      end

      def rules(stylesheet)
        found = []
        preludes = []
        text = +""
        stylesheet.gsub(%r{/\*.*?\*/}m, "").each_char do |char|
          case char
          when "{"
            preludes.push(split(text, ";").last.to_s.strip)
            text = +""
          when "}"
            found << [ preludes.dup, text ]
            preludes.pop
            text = +""
          else
            text << char
          end
        end
        found
      end

      def split(text, separator)
        parts = [ +"" ]
        depth = 0
        text.each_char do |char|
          depth += 1 if char == "("
          depth -= 1 if char == ")"
          char == separator && depth.zero? ? parts << +"" : parts.last << char
        end
        parts.reject { |part| part.strip.empty? }
      end

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

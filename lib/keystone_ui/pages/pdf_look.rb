# frozen_string_literal: true

require "keystone_ui/look_choice"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/pdf_document"

module KeystoneUi
  module Pages
    class PdfLook
      Font = Data.define(:name, :files)
      BUILT_IN_FONT = Font.new(name: "Helvetica", files: nil)

      OKLAB_TO_LMS = [ [ 0.3963377774, 0.2158037573 ], [ -0.1055613458, -0.0638541728 ], [ -0.0894841775, -1.2914855480 ] ].freeze
      POINTS_PER_UNIT = { "rem" => 12.0, "em" => 12.0, "px" => 0.75, "pt" => 1.0 }.freeze
      ROOTS = [ ":root", ":host", "html" ].freeze
      LMS_TO_SRGB = [ [ 4.0767416621, -3.3077115913, 0.2309699292 ], [ -1.2684380046, 2.6097574011, -0.3413193965 ], [ -0.0041960863, -0.7034186147, 1.7076147010 ] ].freeze

      FONT_WEIGHTS = { "normal" => 400, "bold" => 700 }.freeze
      FONT_STYLES = { normal: [ "normal", 400 ], bold: [ "normal", 700 ], italic: [ "italic", 400 ] }.freeze

      def self.host
        configuration = KeystoneUi.configuration
        new(PdfDocument.stylesheet, look: KeystoneUi::LookChoice.new(looks: configuration.looks.keys, default: configuration.default_look).name, font_files: method(:served_file))
      end

      def self.served_file(url)
        path = Rails.public_path.join(url.delete_prefix("/"))
        return path.to_s if path.file?

        Rails.application.assets.load_path.find(url.delete_prefix("/").delete_prefix("assets/"))&.path&.to_s
      end

      def initialize(stylesheet, look: nil, font_files: ->(_url) { nil })
        @look = look
        @font_files = font_files
        rules = rules(stylesheet)
        @faces = faces(rules)
        @values = declarations(rules).sort_by.with_index { |(rank, _declaration), index| [ rank, index ] }.to_h { |_rank, declaration| declaration }
      end

      def color(name)
        css = value(name)
        return oklch_hex(css) if css.start_with?("oklch(")

        css.delete_prefix("#").upcase
      end

      def font(name)
        families = value(name) == "inherit" ? value("font-family") : value(name)
        family = split(families, ",").map { |listed| listed.strip.delete("\"'") }.find { |listed| @faces.key?(listed) }
        return BUILT_IN_FONT unless family

        Font.new(name: family, files: FONT_STYLES.transform_values { |(style, weight)| true_type(face(family, style, weight)) })
      end

      def weight(name)
        value(name).to_i
      end

      def points(name)
        length = value(name)
        length.to_f * POINTS_PER_UNIT.fetch(length[/[a-z]+\z/], 0.0)
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

      def faces(rules)
        rules.select { |preludes, _body| preludes.last == "@font-face" }
             .map { |_preludes, body| split(body, ";").to_h { |declaration| declaration.split(":", 2).map(&:strip) } }
             .group_by { |face| face["font-family"].to_s.delete("\"'") }
      end

      def face(family, style, weight)
        faces = @faces[family].select { |face| face.fetch("font-style", "normal") == style }.presence || @faces[family]
        faces.min_by do |face|
          weights = face.fetch("font-weight", "normal").split.map { |listed| FONT_WEIGHTS.fetch(listed) { listed.to_i } }
          (weight - weight.clamp(weights.min, weights.max)).abs
        end
      end

      def true_type(face)
        url = face["src"].to_s[/url\(["']?([^"')]+)["']?\)/, 1].sub(/\.[^.\/]+\z/, ".ttf")
        @font_files.call(url) || raise(PrintFailed, "The PDF needs a TrueType copy of the #{face["font-family"].delete("\"'")} font at #{url}, beside the font file the stylesheet loads, and none is served.")
      end

      def declarations(rules)
        rules.flat_map do |preludes, body|
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

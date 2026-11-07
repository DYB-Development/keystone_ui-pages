# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfLook
      def initialize(stylesheet)
        @values = stylesheet.scan(/\{([^{}]*)\}/).flatten.flat_map { |block| block.split(";") }.to_h { |declaration| declaration.split(":", 2).map(&:strip) }
      end

      def color(name)
        value(name).delete_prefix("#").upcase
      end

      def value(name)
        @values.fetch(name).gsub(/var\((--[\w-]+)\)/) { value(Regexp.last_match(1)) }
      end
    end
  end
end

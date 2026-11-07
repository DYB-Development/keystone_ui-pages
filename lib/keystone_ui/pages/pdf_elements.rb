# frozen_string_literal: true

module KeystoneUi
  module Pages
    module PdfElements
      HEADING_SIZES = { "sm" => 14, "md" => 18, "lg" => 24 }.freeze
      LABEL_SIZE = 10

      module_function

      def heading(surface, fields)
        surface.text(fields[:text], size: HEADING_SIZES.fetch(fields[:size].to_s, HEADING_SIZES["md"]))
        surface.text(fields[:note], size: LABEL_SIZE) if fields[:note].present?
      end

      def label(surface, fields)
        surface.text(fields[:text], size: LABEL_SIZE)
      end
    end
  end
end

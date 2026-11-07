# frozen_string_literal: true

module KeystoneUi
  module Pages
    module PdfElements
      HEADING_SIZES = { "sm" => "--text-lg", "md" => "--text-2xl", "lg" => "--text-4xl" }.freeze
      NOTE_SIZE = "--text-sm"
      LABEL_SIZE = "--text-xs"

      module_function

      def heading(surface, fields)
        surface.text(fields[:text], size: HEADING_SIZES.fetch(fields[:size].to_s, HEADING_SIZES["md"]), font: "--ks-font-heading", weight: "--ks-font-weight-heading", color: "--ks-color-text")
        surface.text(fields[:note], size: NOTE_SIZE, color: "--ks-color-text-muted") if fields[:note].present?
      end

      def label(surface, fields)
        surface.text(fields[:text], size: LABEL_SIZE, font: "--ks-font-body", weight: "--ks-font-weight-strong", color: "--ks-color-text-muted", uppercase: true)
      end
    end
  end
end

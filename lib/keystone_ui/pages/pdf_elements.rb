# frozen_string_literal: true

require "nokogiri"
require "rails-html-sanitizer"

module KeystoneUi
  module Pages
    module PdfElements
      HEADING_SIZES = { "sm" => "--text-lg", "md" => "--text-2xl", "lg" => "--text-4xl" }.freeze
      NOTE_SIZE = "--text-sm"
      LABEL_SIZE = "--text-xs"
      PARAGRAPH_SIZE = "--text-base"
      PARAGRAPH_TAGS = %w[p br a strong b em i].freeze
      PARAGRAPH_MARKS = { "strong" => :bold, "b" => :bold, "em" => :italic, "i" => :italic }.freeze

      module_function

      def heading(surface, fields)
        surface.text(fields[:text], size: HEADING_SIZES.fetch(fields[:size].to_s, HEADING_SIZES["md"]), font: "--ks-font-heading", weight: "--ks-font-weight-heading", color: "--ks-color-text")
        surface.text(fields[:note], size: NOTE_SIZE, color: "--ks-color-text-muted") if fields[:note].present?
      end

      def label(surface, fields)
        surface.text(fields[:text], size: LABEL_SIZE, font: "--ks-font-body", weight: "--ks-font-weight-strong", color: "--ks-color-text-muted", uppercase: true, tracking: "--tracking-wider")
      end

      def paragraph(surface, fields)
        rich_paragraphs(fields[:text]["html"]).each { |paragraph| surface.rich_text(runs(paragraph), size: PARAGRAPH_SIZE) }
      end

      def rich_paragraphs(html)
        stored = Nokogiri::HTML5.fragment(html.to_s)
        stored.css("script, style").each(&:remove)
        Nokogiri::HTML5.fragment(Rails::HTML5::SafeListSanitizer.new.sanitize(stored.to_html, tags: PARAGRAPH_TAGS, attributes: %w[href])).css("p")
      end

      def runs(node, marks = {})
        node.children.flat_map do |child|
          next [ { text: "\n" } ] if child.name == "br"
          next [ { text: child.text }.merge(marks) ] if child.text?

          runs(child, marked(child, marks))
        end
      end

      def marked(node, marks)
        return marks.merge(link: node["href"]).compact if node.name == "a"
        return marks.merge(PARAGRAPH_MARKS[node.name] => true) if PARAGRAPH_MARKS.key?(node.name)

        marks
      end
    end
  end
end

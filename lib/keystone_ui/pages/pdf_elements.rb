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
      ALERT_TITLE_SIZE = "--text-base"
      ALERT_MESSAGE_SIZE = "--text-sm"
      VALUE_LIST_SIZE = "--text-base"
      VALUE_LIST_NOTE_SIZE = "--text-xs"
      VALUE_LIST_LABEL_SHARE = Rational(2, 5)
      VALUE_LIST_ROW_PADDING = 2
      VALUE_LIST_ALIGNMENTS = { "end" => :right }.freeze
      ALERT_TITLE_GAP = 1
      ALERT_PADDING = 4
      ALERT_RADIUS = 0.75
      SPACING = "--ks-spacing"
      ALERT_TONES = { "info" => "info", "success" => "success", "warning" => "warning", "error" => "danger" }.freeze
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

      def alert(surface, fields)
        tone = ALERT_TONES.fetch(fields[:type].to_s, ALERT_TONES["info"])
        surface.box(fill: "--ks-color-#{tone}-50", padding: [ SPACING, ALERT_PADDING ], radius: [ "--ks-radius-surface", ALERT_RADIUS ]) do
          if fields[:title].present?
            surface.text(fields[:title], size: ALERT_TITLE_SIZE, weight: "--ks-font-weight-heading", color: "--ks-color-#{tone}-800")
            surface.space(SPACING, ALERT_TITLE_GAP)
          end
          surface.text(fields[:message], size: ALERT_MESSAGE_SIZE, color: "--ks-color-#{tone}-800")
        end
      end

      def value_list(surface, fields)
        Array(fields[:rows].presence).each do |entry|
          surface.space(SPACING, VALUE_LIST_ROW_PADDING)
          surface.row([ VALUE_LIST_LABEL_SHARE, 1 - VALUE_LIST_LABEL_SHARE ]) do |index|
            index.zero? ? value_list_label(surface, entry) : value_list_value(surface, entry, VALUE_LIST_ALIGNMENTS[fields[:align].to_s])
          end
          surface.space(SPACING, VALUE_LIST_ROW_PADDING)
        end
      end

      def value_list_label(surface, entry)
        surface.text(entry[:label], size: VALUE_LIST_SIZE, weight: total_weight(entry), color: total?(entry) ? "--ks-color-text" : "--ks-color-text-secondary")
        surface.text(entry[:note], size: VALUE_LIST_NOTE_SIZE, weight: total_weight(entry), color: "--ks-color-text-muted") if entry[:note].present?
      end

      def value_list_value(surface, entry, align)
        surface.text(entry[:value].presence || entry[:fallback], size: VALUE_LIST_SIZE, weight: total_weight(entry), color: "--ks-color-text", align: align)
      end

      def total_weight(entry)
        "--ks-font-weight-strong" if total?(entry)
      end

      def total?(entry)
        entry[:total].to_s == "true"
      end

      def paragraph(surface, fields)
        text = fields[:text]
        return drawn_paragraph(surface, [ { text: text.to_s } ]) unless text.is_a?(Hash)

        rich_paragraphs(text["html"]).each { |paragraph| drawn_paragraph(surface, runs(paragraph)) }
      end

      def drawn_paragraph(surface, runs)
        surface.rich_text(runs, size: PARAGRAPH_SIZE, font: "--ks-font-body", color: "--ks-color-text")
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

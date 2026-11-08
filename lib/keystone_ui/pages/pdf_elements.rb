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
      PAGE_LINE_HEIGHT = "line-height"
      ALERT_TITLE_SIZE = "--text-base"
      ALERT_MESSAGE_SIZE = "--text-sm"
      VALUE_LIST_SIZE = "--text-base"
      VALUE_LIST_NOTE_SIZE = "--text-xs"
      VALUE_LIST_LABEL_SHARE = Rational(2, 5)
      VALUE_LIST_ROW_PADDING = 2
      VALUE_LIST_GAP = 4
      VALUE_LIST_ALIGNMENTS = { "end" => :right }.freeze
      BUTTON_SIZE = "--text-base"
      BUTTON_PADDING_ACROSS = 4
      BUTTON_PADDING_DOWN = 2
      ACCORDION_QUESTION_SIZE = "--text-base"
      ACCORDION_ANSWER_SIZE = "--text-sm"
      ACCORDION_PADDING_ACROSS = 6
      ACCORDION_PADDING_DOWN = 4
      ACCORDION_RADIUS = 1.5
      ACCORDION_GAP = 4
      ALERT_TITLE_GAP = 1
      ALERT_PADDING = 4
      ALERT_RADIUS = 0.75
      SPACING = "--ks-spacing"
      ALERT_TONES = { "info" => "info", "success" => "success", "warning" => "warning", "error" => "danger" }.freeze
      TABLE_SIZE = "--text-sm"
      TABLE_ALIGNMENTS = { "start" => :left, "end" => :right }.freeze
      PARAGRAPH_TAGS = %w[p br a strong b em i].freeze
      PARAGRAPH_MARKS = { "strong" => :bold, "b" => :bold, "em" => :italic, "i" => :italic }.freeze

      module_function

      def heading(surface, fields)
        size = HEADING_SIZES.fetch(fields[:size].to_s, HEADING_SIZES["md"])
        surface.text(fields[:text], size: size, font: "--ks-font-heading", weight: "--ks-font-weight-heading", color: "--ks-color-text", leading: line_height(size))
        surface.text(fields[:note], size: NOTE_SIZE, color: "--ks-color-text-muted", leading: line_height(NOTE_SIZE)) if fields[:note].present?
      end

      def left_out(_surface, _fields); end

      def button(surface, fields)
        surface.boxed_text(fields[:label], size: BUTTON_SIZE, font: "--ks-font-body", weight: "--ks-font-weight-strong", color: "--ks-color-on-accent", leading: line_height(BUTTON_SIZE),
                                           fill: "--ks-color-accent", padding: [ SPACING, BUTTON_PADDING_ACROSS, BUTTON_PADDING_DOWN ], radius: [ "--ks-radius-control", 1 ],
                                           border: { width: "--ks-border-width-control", color: "--ks-color-on-accent" }, link: fields[:href].presence)
      end

      def accordion(surface, fields)
        Array(fields[:items].presence).each_with_index do |item, position|
          surface.space(SPACING, ACCORDION_GAP) if position.positive?
          surface.box(padding: [ SPACING, ACCORDION_PADDING_ACROSS, ACCORDION_PADDING_DOWN ], radius: [ "--ks-radius-surface", ACCORDION_RADIUS ],
                      border: { width: "--ks-border-width", color: "--ks-color-border-subtle" }) do
            surface.text(item[:question], size: ACCORDION_QUESTION_SIZE, font: "--ks-font-body", weight: "--ks-font-weight-heading", color: "--ks-color-text-display", leading: PAGE_LINE_HEIGHT)
            surface.space(SPACING, ACCORDION_PADDING_DOWN)
            surface.text(item[:answer], size: ACCORDION_ANSWER_SIZE, font: "--ks-font-body", color: "--ks-color-text-body", leading: line_height(ACCORDION_ANSWER_SIZE))
          end
        end
      end

      def line_height(size)
        "#{size}--line-height"
      end

      def label(surface, fields)
        surface.text(fields[:text], size: LABEL_SIZE, font: "--ks-font-body", weight: "--ks-font-weight-strong", color: "--ks-color-text-muted", uppercase: true, tracking: "--tracking-wider", leading: line_height(LABEL_SIZE))
      end

      def alert(surface, fields)
        tone = ALERT_TONES.fetch(fields[:type].to_s, ALERT_TONES["info"])
        surface.box(fill: "--ks-color-#{tone}-50", padding: [ SPACING, ALERT_PADDING ], radius: [ "--ks-radius-surface", ALERT_RADIUS ]) do
          if fields[:title].present?
            surface.text(fields[:title], size: ALERT_TITLE_SIZE, weight: "--ks-font-weight-heading", color: "--ks-color-#{tone}-800", leading: PAGE_LINE_HEIGHT)
            surface.space(SPACING, ALERT_TITLE_GAP)
          end
          surface.text(fields[:message], size: ALERT_MESSAGE_SIZE, color: "--ks-color-#{tone}-800", leading: line_height(ALERT_MESSAGE_SIZE))
        end
      end

      def value_list(surface, fields)
        Array(fields[:rows].presence).each_with_index do |entry, position|
          surface.rule(width: "--ks-border-width", color: "--ks-color-border") if position.positive?
          surface.space(SPACING, VALUE_LIST_ROW_PADDING)
          surface.row([ VALUE_LIST_LABEL_SHARE, 1 - VALUE_LIST_LABEL_SHARE ], gap: [ SPACING, VALUE_LIST_GAP ]) do |index|
            index.zero? ? value_list_label(surface, entry) : value_list_value(surface, entry, VALUE_LIST_ALIGNMENTS[fields[:align].to_s])
          end
          surface.space(SPACING, VALUE_LIST_ROW_PADDING)
        end
      end

      def value_list_label(surface, entry)
        surface.text(entry[:label], size: VALUE_LIST_SIZE, weight: total_weight(entry), color: total?(entry) ? "--ks-color-text" : "--ks-color-text-secondary", leading: PAGE_LINE_HEIGHT)
        surface.text(entry[:note], size: VALUE_LIST_NOTE_SIZE, weight: total_weight(entry), color: "--ks-color-text-muted", leading: line_height(VALUE_LIST_NOTE_SIZE)) if entry[:note].present?
      end

      def value_list_value(surface, entry, align)
        surface.text(entry[:value].presence || entry[:fallback], size: VALUE_LIST_SIZE, weight: total_weight(entry), color: "--ks-color-text", align: align, leading: PAGE_LINE_HEIGHT)
      end

      def total_weight(entry)
        "--ks-font-weight-strong" if total?(entry)
      end

      def total?(entry)
        entry[:total].to_s == "true"
      end

      def data_table(surface, fields)
        columns = Array(fields[:columns].presence)
        heading = table_row(columns, columns.map { |column| column[:label] })
        items = Array(fields[:items].presence).map { |item| item.to_h.stringify_keys }
        surface.table(heading, items.each_index.flat_map { |index| item_rows(columns, items, index, fields) })
      end

      def item_rows(columns, items, index, fields)
        row = table_row(columns, columns.map { |column| items[index][column[:key].to_s] })
        key = fields[:group_by].to_s
        group = items[index][key] if key.present?
        return [ row ] if group.nil? || (index.positive? && items[index - 1][key] == group)

        [ group_row(columns, group, fields[:group_totals]), row ]
      end

      def group_row(columns, group, totals)
        subtotals = totals.to_h.stringify_keys.fetch(group.to_s, {}).to_h.stringify_keys
        table_row(columns, columns.each_with_index.map { |column, index| index.zero? ? group : subtotals[column[:key].to_s] })
      end

      def table_row(columns, texts)
        { cells: columns.zip(texts).each_with_index.map { |(column, text), index| { text: text.to_s, size: TABLE_SIZE, align: table_alignment(column, index == columns.size - 1) } } }
      end

      def table_alignment(column, last)
        TABLE_ALIGNMENTS.fetch(column[:align].to_s) { last ? :right : :left }
      end

      def paragraph(surface, fields)
        text = fields[:text]
        return drawn_paragraph(surface, [ { text: text.to_s } ]) unless text.is_a?(Hash)

        rich_paragraphs(text["html"]).each { |paragraph| drawn_paragraph(surface, runs(paragraph)) }
      end

      def drawn_paragraph(surface, runs)
        surface.rich_text(runs, size: PARAGRAPH_SIZE, font: "--ks-font-body", color: "--ks-color-text", leading: "--leading-relaxed")
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

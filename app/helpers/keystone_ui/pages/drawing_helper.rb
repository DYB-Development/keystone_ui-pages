# frozen_string_literal: true

require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module DrawingHelper
      NARROW_SPANS = { "1/1" => "col-span-12", "3/4" => "col-span-9", "2/3" => "col-span-8", "1/2" => "col-span-6", "1/3" => "col-span-4", "1/4" => "col-span-3" }.freeze
      WIDE_SPANS = { "1/1" => "@sm:col-span-12", "3/4" => "@sm:col-span-9", "2/3" => "@sm:col-span-8", "1/2" => "@sm:col-span-6", "1/3" => "@sm:col-span-4", "1/4" => "@sm:col-span-3" }.freeze
      ELEMENT_ALIGNMENTS = { "stretch" => "flex flex-col", "start" => "flex justify-start", "center" => "flex justify-center", "end" => "flex justify-end" }.freeze
      COLUMN_ALIGNMENTS = { "top" => "justify-start", "center" => "justify-center", "bottom" => "justify-end" }.freeze
      DRAWING_FORMAT = 2
      SIZED_SECTION_PADDING = "py-[calc(var(--ks-spacing)*16)] lg:py-[calc(var(--ks-spacing)*24)]"
      SHADED_CLASSES = "bg-(color:--ks-color-fill-muted) dark:bg-(color:--ks-color-fill-muted-dark)"
      PLAIN_FIGURE_DIVIDER = "@sm:[.ks-pages-column:has(.ks-metric-plain)+&:has(.ks-metric-plain)]:border-l-(length:--ks-border-width) " \
                             "@sm:[.ks-pages-column:has(.ks-metric-plain)+&:has(.ks-metric-plain)]:border-(color:--ks-color-border) " \
                             "dark:@sm:[.ks-pages-column:has(.ks-metric-plain)+&:has(.ks-metric-plain)]:border-(color:--ks-color-border-dark)"

      def drawn_version(version, values: {})
        key = [ "keystone_ui_pages", DRAWING_FORMAT, version.id, Operations.digest(values.to_h.stringify_keys) ]
        @drawn_page_id = version.page_id
        Rails.cache.fetch(key) { drawn_document(version.document, values: values).to_str }.html_safe
      end

      def reporting_data(page)
        return {} unless page.reporting?

        content_for :head, javascript_include_tag("keystone_ui_pages/reporting", defer: true)
        { page_events: keystone_ui_pages.page_events_path(page.slug), page_slug: page.slug, page_place: page.place }
      end

      def pages_paragraph(text:)
        return ui_paragraph(text: text) unless text.is_a?(Hash)

        rich_paragraphs(text["html"].to_s)
      end

      def drawn_document(document, editing: false, values: {})
        @drawn_values = values.to_h.stringify_keys
        safe_join(document["sections"].map { |section| drawn_section(section, editing) })
      end

      private

      def rich_paragraphs(html)
        stored = Nokogiri::HTML5.fragment(html)
        stored.css("script, style").each(&:remove)
        fragment = Nokogiri::HTML5.fragment(Rails::HTML5::SafeListSanitizer.new.sanitize(stored.to_html, tags: %w[p br a], attributes: %w[href]))
        fragment.css("a:not([href])").each { |link| link.replace(link.children) }
        fragment.css("p").each { |paragraph| paragraph["class"] = "ks-paragraph" }
        fragment.css("a[href^='http://'], a[href^='https://']").each { |link| link["target"], link["rel"] = "_blank", "noopener noreferrer" }
        fragment.to_html.html_safe
      end

      def drawn_section(section, editing)
        return if hidden?(section) && !editing

        spacing = Keystone::Ui::SectionComponent::SPACING_CLASSES.fetch((section["spacing"] || Operations::DEFAULTS[:section]["spacing"]).to_sym)
        data = editing ? { section_id: section["id"], hidden: hidden?(section) || nil }.compact : {}
        shading = SHADED_CLASSES if section["background"] == "shaded"
        tag.section(section_content(section, editing), class: [ "ks-pages-section flex flex-col gap-6 print:break-inside-avoid #{spacing}", shading ].compact.join(" "), data: data)
      end

      def section_content(section, editing)
        rows = safe_join(section["rows"].map { |row| drawn_row(row, editing) })
        width = section["width"]
        return rows if width.nil? || width == "none"

        tag.div(rows, class: "ks-page #{Keystone::Ui::PageComponent::MAX_WIDTH_CLASSES.fetch(width.to_sym)} w-full flex flex-col gap-6 #{SIZED_SECTION_PADDING}")
      end

      def drawn_row(row, editing)
        return if hidden?(row) && !editing

        gap = Keystone::Ui::GridComponent::GAP_CLASSES.fetch((row["gap"] || Operations::DEFAULTS[:row]["gap"]).to_sym)
        share = Operations::SHARES.fetch(row["columns"].size, "1/1")
        columns = row["columns"].map { |column| drawn_column(column, editing, share) }
        data = editing ? { row_id: row["id"], hidden: hidden?(row) || nil }.compact : {}
        tag.div(safe_join(columns), class: "ks-pages-row grid grid-cols-12 #{gap}", data: data)
      end

      def drawn_column(column, editing, share)
        elements = safe_join(column["elements"].map { |element| editing ? edited_element(element) : drawn_element(element) })
        spans = "#{PLAIN_FIGURE_DIVIDER} #{NARROW_SPANS.fetch(column["narrow"] || Operations::DEFAULTS[:column]["narrow"])} #{WIDE_SPANS.fetch(column['wide'] || share)} #{COLUMN_ALIGNMENTS.fetch(column["align"] || Operations::DEFAULTS[:column]["align"])}"
        return tag.div(elements, class: "ks-pages-column flex flex-col gap-4 #{spans}") unless editing

        tag.div(elements, class: "ks-pages-column flex flex-col gap-4 #{spans}", data: { column_id: column["id"] })
      end

      def edited_element(element)
        return missing_element(element) unless KeystoneUi::Pages.catalog.find(element["key"])

        wrapped_element(element, data: { element_id: element["id"], hidden: hidden?(element) || nil }.compact)
      end

      def reported_missing(element)
        Rails.error.report(InvalidDocument.new("No element is registered as #{element["key"]}"), handled: true,
          context: { page_id: @drawn_page_id, element_key: element["key"] })
        nil
      end

      def missing_element(element)
        tag.div("No longer offered: #{element["key"]}", class: "ks-pages-element ks-hint rounded-md border-2 border-dashed border-(--ks-color-border-strong) p-3",
          data: { element_id: element["id"], missing_element: true })
      end

      def drawn_element(element)
        return reported_missing(element) unless KeystoneUi::Pages.catalog.find(element["key"])

        wrapped_element(element, data: { page_element: element["id"] }) unless hidden?(element)
      end

      def hidden?(node)
        condition = node["show_when"]
        condition && (@drawn_values || {})[condition["value"]].to_s != condition["equals"].to_s
      end

      def wrapped_element(element, data: {})
        tag.div(component_for(element), class: "ks-pages-element print:[&_tr]:break-inside-avoid print:[&_.ks-value-list-row]:break-inside-avoid #{wrapper_classes(element)} #{ELEMENT_ALIGNMENTS.fetch(element["align"] || KeystoneUi::Pages.catalog.find(element["key"])&.align || Operations::DEFAULTS[:element]["align"])}", data: data)
      end

      def field_value(field, value)
        return value.map { |entry| entry.is_a?(Hash) ? entry.symbolize_keys : entry } if field[:kind] == :data && value.is_a?(Array)
        return value.map { |entry| Keystone::Ui::Column.new(entry["key"].to_s.to_sym, entry["label"], align: entry["align"].presence&.to_sym) } if field[:as] == :pairs && value.is_a?(Array)
        return value.map { |entry| entry_with_defaults(field, entry) } if field[:kind] == :list && value.is_a?(Array)
        return [] if (field[:kind] == :list || (field[:kind] == :data && field[:default].is_a?(Array))) && value.blank?
        return nil if field[:kind] == :data && value.blank?
        return value if value.blank?
        return ERB::Util.html_escape(value) if field[:as] == :escaped_text
        return value.to_sym if field[:as] == :key
        return value.to_s == "true" if field[:kind] == :yes_or_no
        return value.to_sym if field[:kind] == :one_of
        return value unless field[:kind] == :number

        value.to_s.include?(".") ? value.to_f : value.to_i
      end

      def entry_with_defaults(field, entry)
        parts = Array(field[:entry]).index_by { |part| part[:key] }
        defaults = parts.transform_values { |part| part[:default] }.compact
        given = entry.to_h.symbolize_keys.to_h { |key, value| [ key, parts[key] ? field_value(parts[key], value) : value ] }
        defaults.merge(given.compact_blank)
      end

      def filled(stored)
        return stored.presence unless stored.is_a?(Hash) && stored.key?("value")

        (@drawn_values || {})[stored["value"]].presence || stored["fallback"].presence || ""
      end

      def wrapper_classes(element)
        definition = KeystoneUi::Pages.catalog.find(element["key"])
        definition.fields.select { |field| field[:classes] }
          .map { |field| field[:classes][element["fields"][field[:key].to_s].presence || field[:default]] }.compact.join(" ")
      end

      def component_for(element)
        definition = KeystoneUi::Pages.catalog.find(element["key"])
        values = definition.fields.reject { |field| field[:classes] }.to_h { |field| [ field[:key].to_sym, field_value(field, filled(element["fields"][field[:key].to_s]) || field[:default]) ] }
        return send(definition.component, **values) unless definition.body

        body = values.delete(definition.body)
        send(definition.component, **values) { body }
      end
    end
  end
end

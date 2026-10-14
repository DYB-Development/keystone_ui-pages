# frozen_string_literal: true

module KeystoneUi
  module Pages
    module DrawingHelper
      NARROW_SPANS = { "1/1" => "col-span-12", "3/4" => "col-span-9", "2/3" => "col-span-8", "1/2" => "col-span-6", "1/3" => "col-span-4", "1/4" => "col-span-3" }.freeze
      WIDE_SPANS = { "1/1" => "@sm:col-span-12", "3/4" => "@sm:col-span-9", "2/3" => "@sm:col-span-8", "1/2" => "@sm:col-span-6", "1/3" => "@sm:col-span-4", "1/4" => "@sm:col-span-3" }.freeze
      SHARES = { 1 => "1/1", 2 => "1/2", 3 => "1/3", 4 => "1/4" }.freeze
      ELEMENT_ALIGNMENTS = { "stretch" => "flex flex-col", "start" => "flex justify-start", "center" => "flex justify-center", "end" => "flex justify-end" }.freeze
      COLUMN_ALIGNMENTS = { "top" => "justify-start", "center" => "justify-center", "bottom" => "justify-end" }.freeze

      def drawn_document(document, editing: false)
        safe_join(document["sections"].map { |section| drawn_section(section, editing) })
      end

      private

      def drawn_section(section, editing)
        spacing = Keystone::Ui::SectionComponent::SPACING_CLASSES.fetch((section["spacing"] || "md").to_sym)
        data = editing ? { section_id: section["id"] } : {}
        tag.section(safe_join(section["rows"].map { |row| drawn_row(row, editing) }), class: "ks-pages-section flex flex-col gap-6 #{spacing}", data: data)
      end

      def drawn_row(row, editing)
        gap = Keystone::Ui::GridComponent::GAP_CLASSES.fetch((row["gap"] || "md").to_sym)
        share = SHARES.fetch(row["columns"].size, "1/1")
        columns = row["columns"].map { |column| drawn_column(column, editing, share) }
        data = editing ? { row_id: row["id"] } : {}
        tag.div(safe_join(columns), class: "ks-pages-row grid grid-cols-12 #{gap}", data: data)
      end

      def drawn_column(column, editing, share)
        elements = safe_join(column["elements"].map { |element| editing ? edited_element(element) : drawn_element(element) })
        spans = "#{NARROW_SPANS.fetch(column['narrow'] || '1/1')} #{WIDE_SPANS.fetch(column['wide'] || share)} #{COLUMN_ALIGNMENTS.fetch(column['align'] || 'top')}"
        return tag.div(elements, class: "ks-pages-column flex flex-col gap-4 #{spans}") unless editing

        tag.div(elements, class: "ks-pages-column flex flex-col gap-4 #{spans}", data: { column_id: column["id"] })
      end

      def edited_element(element)
        wrapped_element(element, data: { element_id: element["id"] })
      end

      def drawn_element(element)
        wrapped_element(element)
      end

      def wrapped_element(element, data: {})
        tag.div(component_for(element), class: "ks-pages-element #{ELEMENT_ALIGNMENTS.fetch(element['align'] || 'stretch')}", data: data)
      end

      def field_value(field, value)
        return value if value.blank?
        return value.to_s == "true" if field[:kind] == :yes_or_no
        return value.to_sym if field[:kind] == :one_of
        return value unless field[:kind] == :number

        value.to_s.include?(".") ? value.to_f : value.to_i
      end

      def component_for(element)
        definition = KeystoneUi::Pages.catalog.find(element["key"])
        values = definition.fields.to_h { |field| [ field[:key].to_sym, field_value(field, element["fields"][field[:key].to_s].presence || field[:default]) ] }
        return send(definition.component, **values) unless definition.body

        body = values.delete(definition.body)
        send(definition.component, **values) { body }
      end
    end
  end
end

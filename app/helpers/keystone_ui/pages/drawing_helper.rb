# frozen_string_literal: true

module KeystoneUi
  module Pages
    module DrawingHelper
      def drawn_document(document, editing: false)
        safe_join(document["sections"].map { |section| drawn_section(section, editing) })
      end

      private

      def drawn_section(section, editing)
        tag.section(safe_join(section["rows"].map { |row| drawn_row(row, editing) }), class: "ks-pages-section flex flex-col gap-6 py-8")
      end

      def drawn_row(row, editing)
        tag.div(safe_join(row["columns"].map { |column| drawn_column(column, editing) }), class: "ks-pages-row flex flex-col gap-6 sm:flex-row")
      end

      def drawn_column(column, editing)
        elements = safe_join(column["elements"].map { |element| editing ? edited_element(element) : drawn_element(element) })
        return tag.div(elements, class: "ks-pages-column flex flex-1 flex-col gap-4") unless editing

        tag.div(elements, class: "ks-pages-column flex flex-1 flex-col gap-4 min-h-16", data: { column_id: column["id"] })
      end

      def edited_element(element)
        tag.div(drawn_element(element), class: "contents", data: { element_id: element["id"] })
      end

      def drawn_element(element)
        definition = KeystoneUi::Pages.catalog.find(element["key"])
        values = definition.fields.to_h { |field| [ field[:key].to_sym, element["fields"][field[:key].to_s] ] }
        send(definition.component, **values)
      end
    end
  end
end

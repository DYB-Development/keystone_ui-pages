# frozen_string_literal: true

module KeystoneUi
  module Pages
    module DrawingHelper
      def drawn_document(document)
        safe_join(document["sections"].map { |section| drawn_section(section) })
      end

      private

      def drawn_section(section)
        tag.section(safe_join(section["rows"].map { |row| drawn_row(row) }), class: "ks-pages-section flex flex-col gap-6 py-8")
      end

      def drawn_row(row)
        tag.div(safe_join(row["columns"].map { |column| drawn_column(column) }), class: "ks-pages-row flex flex-col gap-6 sm:flex-row")
      end

      def drawn_column(column)
        tag.div(safe_join(column["elements"].map { |element| drawn_element(element) }), class: "ks-pages-column flex flex-1 flex-col gap-4")
      end

      def drawn_element(element)
        definition = KeystoneUi::Pages.catalog.find(element["key"])
        send(definition.component, **element["fields"].symbolize_keys)
      end
    end
  end
end

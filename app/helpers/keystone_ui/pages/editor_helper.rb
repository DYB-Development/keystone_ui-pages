# frozen_string_literal: true

module KeystoneUi
  module Pages
    module EditorHelper
      def editor_props(page)
        {
          elements: KeystoneUi::Pages.catalog.elements.map { |element| { key: element.key, name: element.name, fields: element.fields } },
          canvas: drawn_document(page.document, editing: true),
          document: page.document,
          elements_url: manage_page_elements_path(page),
          sections_url: manage_page_sections_path(page),
          columns_url: manage_page_columns_path(page),
          token: form_authenticity_token
        }
      end
    end
  end
end

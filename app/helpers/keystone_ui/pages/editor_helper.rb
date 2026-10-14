# frozen_string_literal: true

require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module EditorHelper
      def editor_props(page)
        {
          elements: KeystoneUi::Pages.catalog.elements.map { |element| element.to_h.slice(:key, :name, :fields, :icon, :group) },
          canvas: drawn_document(page.document, editing: true),
          document: page.document,
          elements_url: manage_page_elements_path(page),
          sections_url: manage_page_sections_path(page),
          columns_url: manage_page_columns_path(page),
          rows_url: manage_page_rows_path(page),
          nodes_url: "#{manage_page_path(page)}/nodes",
          arrangements: Operations::ARRANGEMENTS,
          defaults: Operations::DEFAULTS,
          shares: Operations::SHARES,
          token: form_authenticity_token
        }
      end
    end
  end
end

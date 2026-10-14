# frozen_string_literal: true

module KeystoneUi
  module Pages
    module EditorHelper
      def editor_props(_page)
        { elements: KeystoneUi::Pages.catalog.elements.map { |element| { key: element.key, name: element.name, fields: element.fields } } }
      end
    end
  end
end

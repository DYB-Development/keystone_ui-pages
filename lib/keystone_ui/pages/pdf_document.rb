# frozen_string_literal: true

module KeystoneUi
  module Pages
    module PdfDocument
      module_function

      def html(version, values: {})
        KeystoneUi::Pages::PagesController.render(template: "keystone_ui/pages/pdfs/show", layout: false, assigns: { version: version, values: values })
      end
    end
  end
end

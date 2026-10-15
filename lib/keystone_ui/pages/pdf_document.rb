# frozen_string_literal: true

module KeystoneUi
  module Pages
    module PdfDocument
      module_function

      def html(version, values: {})
        KeystoneUi::Pages::PagesController.render(template: "keystone_ui/pages/pdfs/show", layout: false, assigns: { version: version, values: values, stylesheet: stylesheet })
      end

      def stylesheet
        Rails.application.assets.load_path.find(Pages.pdf_stylesheet)&.content.to_s
      end
    end
  end
end

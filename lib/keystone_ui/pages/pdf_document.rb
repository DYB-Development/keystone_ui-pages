# frozen_string_literal: true

module KeystoneUi
  module Pages
    module PdfDocument
      module_function

      def stylesheet
        Rails.application.assets.load_path.find(Pages.pdf_stylesheet)&.content.to_s.dup.force_encoding(Encoding::UTF_8)
      end
    end
  end
end

# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfJob < ActiveJob::Base
      def perform(page, values)
        KeystoneUi::Pages.pdf(page, values: values)
      end
    end
  end
end

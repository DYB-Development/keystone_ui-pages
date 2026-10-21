# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PdfJob < ActiveJob::Base
      def perform(page, values, version = nil)
        KeystoneUi::Pages.pdf(page, values: values, version: version)
      end
    end
  end
end

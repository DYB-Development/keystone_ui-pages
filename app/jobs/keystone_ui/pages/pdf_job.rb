# frozen_string_literal: true

require "keystone_ui/pages/print_failed"

module KeystoneUi
  module Pages
    class PdfJob < ActiveJob::Base
      def perform(page, values, version = nil)
        KeystoneUi::Pages.pdf(page, values: values, version: version)
      rescue PrintFailed => error
        Rails.error.report(error, handled: true, context: { page_id: page.id, page_name: page.name })
      end
    end
  end
end

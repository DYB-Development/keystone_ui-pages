# frozen_string_literal: true

require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    class PdfJob < ActiveJob::Base
      def perform(page, values, version = nil)
        KeystoneUi::Pages.pdf(page, values: values, version: version)
      rescue PrintFailed
        nil
      end
    end
  end
end

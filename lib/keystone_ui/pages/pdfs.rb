# frozen_string_literal: true

require "keystone_ui/pages/operations"
require "keystone_ui/pages/pdf_document"
require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    module Pdfs
      module_function

      def for(page, values: {})
        version = page.versions.live.first
        digest = Operations.digest(values.to_h.stringify_keys)
        Pdf.create!(version: version, values_digest: digest,
          file: { io: StringIO.new(Printer.pdf(PdfDocument.html(version, values: values))), filename: "#{page.slug}.pdf", content_type: "application/pdf" })
      end
    end
  end
end

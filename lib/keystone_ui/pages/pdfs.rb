# frozen_string_literal: true

require "keystone_ui/pages/operations"
require "keystone_ui/pages/pdf_drawing"

module KeystoneUi
  module Pages
    module Pdfs
      module_function

      def for(page, values: {}, version: nil)
        version = version ? page.versions.find_by(number: version) : page.versions.live.first
        digest = Operations.digest(values.to_h.stringify_keys)
        Pdf.find_by(version: version, values_digest: digest) || Pdf.create!(version: version, values_digest: digest,
          file: { io: StringIO.new(PdfDrawing.pdf(version, values: values)), filename: "#{page.slug}.pdf", content_type: "application/pdf" })
      end
    end
  end
end

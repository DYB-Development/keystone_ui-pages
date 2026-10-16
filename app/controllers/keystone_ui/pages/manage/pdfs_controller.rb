# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class PdfsController < BaseController
        def show
          page = owned_pages.find(params[:page_id])
          return refuse if page.live_version.nil?

          pdf = KeystoneUi::Pages.pdf(page, values: Values.sample(page, helpers.chosen_sample(page)))
          send_data pdf.file.download, filename: "#{page.slug}.pdf", type: "application/pdf"
        end
      end
    end
  end
end

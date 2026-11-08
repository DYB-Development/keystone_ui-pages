# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class PdfsController < BaseController
        def show
          page = owned_pages.find(params[:page_id])
          return refuse if page.live_version.nil?

          pdf = KeystoneUi::Pages.pdf(page, values: sample_values(page))
          send_data pdf.file.download, filename: "#{page.slug}.pdf", type: "application/pdf"
        rescue PrintFailed => refusal
          flash[:pdf_refusal] = refusal.message
          redirect_back_or_to manage_pages_path(place: page.place)
        end

        private

        def sample_values(page)
          page.uses_host_values? ? Values.sample(page, helpers.chosen_sample(page)) : {}
        end
      end
    end
  end
end

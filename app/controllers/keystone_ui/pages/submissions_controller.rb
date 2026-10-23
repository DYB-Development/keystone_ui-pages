# frozen_string_literal: true

require "keystone_ui/pages/submission"
require "keystone_ui/pages/submissions"
require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    class SubmissionsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks

      def create
        page = owned_pages.find_by(slug: params[:slug])
        version = page&.versions&.find_by(number: params[:number])
        form = version && Operations.elements(version.document).find { |element| element["id"] == params[:element_id] && element["key"] == "form" }

        KeystoneUi::Pages.submission_handler(page.place).call(Submission.new(page: page, version: version, form_name: Submissions.form_name(form), element_id: form["id"], values: Submissions.accepted(form, params), request: request))
        head :no_content
      end
    end
  end
end

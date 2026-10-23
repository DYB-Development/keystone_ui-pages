# frozen_string_literal: true

require "keystone_ui/pages/submission"
require "keystone_ui/pages/submissions"
require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    class SubmissionsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks
      helper KeystoneUiHelper
      helper FormHelper
      layout -> { KeystoneUi::Pages.layout }

      def create
        page = owned_pages.find_by(slug: params[:slug])
        version = page&.versions&.find_by(number: params[:number])
        form = version && Operations.elements(version.document).find { |element| element["id"] == params[:element_id] && element["key"] == "form" }
        handler = form && KeystoneUi::Pages.submission_handler(page.place)
        return head(:not_found) unless handler
        return refuse unless viewable?(page)

        values = Submissions.accepted(form, params)
        problems = Submissions.problems(form, values)
        return render(:refused, status: :unprocessable_entity, locals: { form: form, version: version, problems: problems, values: values }) if problems.any?

        handler.call(Submission.new(page: page, version: version, form_name: Submissions.form_name(form), element_id: form["id"], values: values, request: request))
        @element_id = form["id"]
        @thank_you = Submissions.thank_you(form)
      end
    end
  end
end

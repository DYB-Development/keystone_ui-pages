# frozen_string_literal: true

require "keystone_ui/pages/submissions"

module KeystoneUi
  module Pages
    module FormHelper
      FIELD_TYPES = { "text" => :text, "email" => :email, "long_text" => :textarea, "choice" => :select, "checkbox" => :checkbox }.freeze
      TOKEN_PLACEHOLDER = "keystone-ui-pages-form-token"

      def pages_form(form_name:, fields:, submit_label:, thank_you:, element_id:, version:, problems: {}, values: {})
        content = safe_join(fields.map { |field| form_field(field, problems, values) } + [ ui_button(label: submit_label) ])
        return tag.div(content, class: "ks-form") unless version

        content_tag("turbo-frame", ui_form(action: keystone_ui_pages.page_form_path(version.page.slug, version.number, element_id)) { token_placeholder + content }, id: form_frame_id(element_id))
      end

      def redrawn_form(form, version, problems:, values:)
        drawn = pages_form(**Submissions.drawing_settings(form), element_id: form["id"], version: version, problems: problems, values: values)
        with_visitor_token(drawn.to_str).html_safe
      end

      def form_frame_id(element_id)
        "keystone-ui-pages-form-#{element_id}"
      end

      def without_visitor_tokens(html)
        html.gsub(/<input type="hidden" name="#{request_forgery_protection_token}" value="(?!#{TOKEN_PLACEHOLDER})[^"]*"[^>]*>/, "")
      end

      def with_visitor_token(html)
        html.gsub(TOKEN_PLACEHOLDER) { protect_against_forgery? ? form_authenticity_token : "" }
      end

      private

      def token_placeholder
        tag.input(type: "hidden", name: request_forgery_protection_token, value: TOKEN_PLACEHOLDER, autocomplete: "off")
      end

      def form_field(field, problems, values)
        name = field[:name].to_s
        ui_form_field(attribute: name, label: field[:label], type: FIELD_TYPES.fetch(field[:kind].to_s, :text), required: field[:required].to_s == "true",
          errors: Array(problems[name]), value: values[name], options: Submissions.choices(field[:choices]).map { |choice| [ choice, choice ] })
      end
    end
  end
end

# frozen_string_literal: true

require "keystone_ui/pages/submissions"
require "keystone_ui/pages/form_field_kinds"

module KeystoneUi
  module Pages
    module FormHelper
      TOKEN_PLACEHOLDER = "keystone-ui-pages-form-token"

      def pages_form(form_name:, fields:, submit_label:, thank_you:, element_id:, version:, after_submitting: nil, next_address: nil, problems: {}, values: {}, failure: nil)
        content = safe_join([ (ui_alert(message: failure, type: :error) if failure) ].compact + fields.map { |field| form_field(field, problems, values) } + [ trap_field, turnstile_widget, ui_button(label: submit_label) ].compact)
        return tag.div(content, class: "ks-form") unless version

        content_tag("turbo-frame", ui_form(action: keystone_ui_pages.page_form_path(version.page.slug, version.number, element_id)) { token_placeholder + content }, id: form_frame_id(element_id), class: "print:hidden")
      end

      def redrawn_form(form, version, problems: {}, values: {}, failure: nil)
        drawn = pages_form(**Submissions.drawing_settings(form), element_id: form["id"], version: version, problems: problems, values: values, failure: failure)
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

      def turnstile_widget
        tag.div(class: "cf-turnstile", data: { sitekey: KeystoneUi::Pages.turnstile_site_key }) if KeystoneUi::Pages.turnstile_site_key.present?
      end

      def trap_field
        tag.div(tag.input(type: "text", name: Submissions::TRAP_NAME, tabindex: -1, autocomplete: "off"), class: "absolute -left-[10000px] h-px w-px overflow-hidden", aria: { hidden: true })
      end

      def token_placeholder
        tag.input(type: "hidden", name: request_forgery_protection_token, value: TOKEN_PLACEHOLDER, autocomplete: "off")
      end

      def form_field(field, problems, values)
        name = field[:name].to_s
        ui_form_field(attribute: name, label: field[:label], type: FormFieldKinds.find(field[:kind]).drawn_as, required: field[:required].to_s == "true",
          errors: Array(problems[name]), value: values[name], options: FormFieldKinds.choices(field[:choices]).map { |choice| [ choice, choice ] })
      end
    end
  end
end

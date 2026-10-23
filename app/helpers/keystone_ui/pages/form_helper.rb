# frozen_string_literal: true

module KeystoneUi
  module Pages
    module FormHelper
      FIELD_TYPES = { "text" => :text, "email" => :email, "long_text" => :textarea }.freeze
      TOKEN_PLACEHOLDER = "keystone-ui-pages-form-token"

      def pages_form(form_name:, fields:, submit_label:, thank_you:, element_id:, version:)
        content = safe_join(fields.map { |field| form_field(field) } + [ ui_button(label: submit_label) ])
        return tag.div(content, class: "ks-form") unless version

        ui_form(action: keystone_ui_pages.page_form_path(version.page.slug, version.number, element_id)) { token_placeholder + content }
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

      def form_field(field)
        ui_form_field(attribute: field[:name], label: field[:label], type: FIELD_TYPES.fetch(field[:kind].to_s, :text), required: field[:required].to_s == "true")
      end
    end
  end
end

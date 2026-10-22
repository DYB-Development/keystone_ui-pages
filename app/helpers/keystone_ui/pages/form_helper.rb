# frozen_string_literal: true

module KeystoneUi
  module Pages
    module FormHelper
      FIELD_TYPES = { "text" => :text, "email" => :email, "long_text" => :textarea }.freeze

      def pages_form(form_name:, fields:, submit_label:, thank_you:, element_id:, version:)
        content = safe_join(fields.map { |field| form_field(field) } + [ ui_button(label: submit_label) ])
        return tag.div(content, class: "ks-form") unless version

        ui_form(action: keystone_ui_pages.page_form_path(version.page.slug, version.number, element_id)) { content }
      end

      private

      def form_field(field)
        ui_form_field(attribute: field[:name], label: field[:label], type: FIELD_TYPES.fetch(field[:kind].to_s, :text), required: field[:required].to_s == "true")
      end
    end
  end
end

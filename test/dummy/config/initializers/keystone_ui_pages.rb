KeystoneUi::Pages.base_controller = "ApplicationController"
KeystoneUi::Pages.editor_layout = "editor"

Rails.application.config.after_initialize do
  KeystoneUi::Pages.catalog.register(key: :testimonial, name: "Testimonial", component: :testimonial,
    fields: [ { key: :quote, label: "Quote", kind: :long_text, default: "It works." } ])
end

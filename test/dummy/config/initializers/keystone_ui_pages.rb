KeystoneUi::Pages.base_controller = "ApplicationController"
KeystoneUi::Pages.editor_layout = "editor"

Rails.application.config.after_initialize do
  KeystoneUi::Pages.catalog.register(key: :testimonial, name: "Testimonial", component: :testimonial,
    fields: [ { key: :quote, label: "Quote", kind: :long_text, default: "It works." } ])
  KeystoneUi::Pages.catalog.leave_out(:copy_button)
end

if Rails.env.development?
  KeystoneUi::Pages::Values.names = { "client_name" => "Client name", "score" => "Score" }
  KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme report", "acme" ], [ "Globex report", "globex" ] ] }
  KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "acme" => { "client_name" => "Acme", "score" => "82" }, "globex" => { "client_name" => "Globex", "score" => "64" } }[choice] }
end

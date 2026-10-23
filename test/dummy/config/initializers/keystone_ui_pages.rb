KeystoneUi::Pages.base_controller = "ApplicationController"
KeystoneUi::Pages.editor_layout = "editor"

Rails.application.config.after_initialize do
  KeystoneUi::Pages.catalog.register(key: :testimonial, name: "Testimonial", component: :testimonial,
    fields: [ { key: :quote, label: "Quote", kind: :long_text, default: "It works." } ])
  KeystoneUi::Pages.catalog.leave_out(:copy_button)
end

if Rails.env.development?
  KeystoneUi::Pages::Values.names = { "client_name" => "Client name", "score" => "Score", "signed_in" => "Signed in", "purchased" => "Purchased" }
  KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme report", "acme" ], [ "Globex report", "globex" ], [ "Anonymous visitor", "visitor" ], [ "Signed-in client", "signed_in_client" ], [ "Client who purchased", "purchased_client" ] ] }
  KeystoneUi::Pages.places = { "paid_content" => "Paid content" }
  KeystoneUi::Pages.register_place("client_portal", label: "Client portal", leaves_out: [ :form ])
  KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { DemoSubmissions.record(submission) })
  KeystoneUi::Pages.access_exceptions = { "public_preview" => "Public preview" }
  KeystoneUi::Pages.view_check_method = :may_view_demo_page?
  KeystoneUi::Pages.refusal_method = :refuse_page
  KeystoneUi::Pages.values_method = :demo_page_values
  KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "acme" => { "client_name" => "Acme", "score" => "82" }, "globex" => { "client_name" => "Globex", "score" => "64" } }.fetch(choice) { DemoValues.for(choice) } }
end

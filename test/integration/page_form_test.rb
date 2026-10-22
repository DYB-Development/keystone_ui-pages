# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PageFormTest < ActionDispatch::IntegrationTest
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@page.document, "form", column_id: column_id)
    @form_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: @form_id, field: "submit_label", value: "Ask us"))
    @page.publish
  end

  test "a published page with a form shows a labelled input for each field and a submit button with the editor's label" do
    get "/pages/contact"

    form = Nokogiri::HTML(response.body)
    assert_equal [ [ "Name", "Email*" ], %w[name email], "Ask us" ],
      [ form.css(".ks-form-field label").map { |label| label.text.gsub(/\s+/, "") }, form.css(".ks-form-field input").map { |input| input["name"] }, form.at_css("button[type=submit]")&.text&.strip ]
  end
end

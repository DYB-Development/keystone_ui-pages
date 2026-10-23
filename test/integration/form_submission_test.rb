# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormSubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission })
    @page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "form", column_id: column_id))
    @form_id = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page.publish
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a place's handler receives the page, the version and the visitor's request for each accepted submission" do
    post "/pages/contact/versions/1/forms/#{@form_id}", params: { name: "Ada", email: "ada@example.com" }

    assert_equal [ [ @page, @page.live_version, "/pages/contact/versions/1/forms/#{@form_id}" ] ], @received.map { |submission| [ submission.page, submission.version, submission.request.path ] }
  end

  test "a submission carries the form's name and each field's name and value" do
    post "/pages/contact/versions/1/forms/#{@form_id}", params: { name: "Ada", email: "ada@example.com" }

    assert_equal [ [ "Contact", { "name" => "Ada", "email" => "ada@example.com" } ] ], @received.map { |submission| [ submission.form_name, submission.values ] }
  end

  test "a submitted value whose name the form does not list in the version it was drawn from never reaches the handler" do
    fields = [ { "label" => "Name", "name" => "name", "kind" => "text" }, { "label" => "Phone", "name" => "phone", "kind" => "text" } ]
    @page.update!(document: KeystoneUi::Pages::Operations.set(@page.document, element_id: @form_id, field: "fields", value: fields))
    @page.publish

    post "/pages/contact/versions/1/forms/#{@form_id}", params: { name: "Ada", phone: "555-0100", admin: "1" }

    assert_equal [ { "name" => "Ada" } ], @received.map(&:values)
  end
end

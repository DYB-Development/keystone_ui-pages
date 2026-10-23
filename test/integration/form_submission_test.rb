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
end

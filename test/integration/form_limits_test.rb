# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormLimitsTest < ActionDispatch::IntegrationTest
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission.values })
    @page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "form", column_id: column_id))
    @form_id = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page.publish
    @address = "/pages/contact/versions/1/forms/#{@form_id}"
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a submission with a value longer than the limit for its field kind never reaches the host's handler" do
    post @address, params: { name: "A" * 201, email: "ada@example.com" }

    assert_equal [ 422, 0 ], [ response.status, @received.size ]
  end
end

# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission })
    @page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "form", column_id: column_id))
    @form_id = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a form set to send the visitor to an address sends them there once the handler has received the submission" do
    chosen("address", "/pages/next-steps")

    post address, params: { name: "Ada", email: "ada@example.com" }

    assert_equal [ 303, "http://www.example.com/pages/next-steps", 1 ], [ response.status, response.location, @received.size ]
  end

  test "a form built before the after-submitting choice existed shows the thank-you message" do
    post address, params: { name: "Ada", email: "ada@example.com" }

    assert_equal [ 200, "Thanks, we will be in touch." ], [ response.status, Nokogiri::HTML(response.body).at_css("turbo-frame")&.text&.strip ]
  end

  test "a refused visitor sees the form with its errors in place of the form when the form is set to send them to an address" do
    chosen("address", "/pages/next-steps")

    post address, params: { name: "Ada", email: "" }

    assert_equal [ 422, "Fill this in", 0 ], [ response.status, Nokogiri::HTML(response.body).at_css("turbo-frame#keystone-ui-pages-form-#{@form_id} .ks-error")&.text, @received.size ]
  end

  test "a form set to show the thank-you message shows it in place of the form even with an address filled in" do
    chosen("thank_you", "/pages/next-steps")

    post address, params: { name: "Ada", email: "ada@example.com" }

    assert_equal [ 200, "Thanks, we will be in touch." ], [ response.status, Nokogiri::HTML(response.body).at_css("turbo-frame#keystone-ui-pages-form-#{@form_id}")&.text&.strip ]
  end

  private

  def chosen(after_submitting, next_address = nil)
    document = KeystoneUi::Pages::Operations.set(@page.document, element_id: @form_id, field: "after_submitting", value: after_submitting)
    document = KeystoneUi::Pages::Operations.set(document, element_id: @form_id, field: "next_address", value: next_address) if next_address
    @page.update!(document: document)
  end

  def address
    @page.publish
    "/pages/contact/versions/#{@page.live_version.number}/forms/#{@form_id}"
  end
end

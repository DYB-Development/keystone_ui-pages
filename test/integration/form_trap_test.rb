# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FormTrapTest < ActionDispatch::IntegrationTest
  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission })
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

  test "every form draws a trap field kept out of the keyboard order, hidden from screen readers and from autofill" do
    get "/pages/contact"

    trap = Nokogiri::HTML(response.body).at_css("form.ks-form input[name=keystone_ui_pages_trap]")
    assert_equal [ "-1", "off", "true" ], [ trap&.[]("tabindex"), trap&.[]("autocomplete"), trap&.parent&.[]("aria-hidden") ]
  end

  test "a submission with the trap field filled reaches the host's handler marked as a bot" do
    post @address, params: { name: "Ada", email: "ada@example.com", keystone_ui_pages_trap: "https://spam.example" }

    assert_equal [ true ], @received.map(&:bot)
  end

  test "a submission with the trap field empty reaches the host's handler marked as not a bot" do
    post @address, params: { name: "Ada", email: "ada@example.com", keystone_ui_pages_trap: "" }

    assert_equal [ false ], @received.map(&:bot)
  end

  test "a visitor marked as a bot gets the same thank-you message, or goes to the same address, as any other visitor" do
    answers = [ nil, "/pages/next-steps" ].flat_map do |next_address|
      if next_address
        document = KeystoneUi::Pages::Operations.set(@page.document, element_id: @form_id, field: "after_submitting", value: "address")
        @page.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: @form_id, field: "next_address", value: next_address))
        @page.publish
      end
      [ "", "spam" ].map do |trap|
        post "/pages/contact/versions/#{@page.live_version.number}/forms/#{@form_id}", params: { name: "Ada", email: "ada@example.com", keystone_ui_pages_trap: trap }
        [ response.status, response.location, Nokogiri::HTML(response.body).at_css("turbo-frame")&.text&.strip ]
      end
    end

    assert_equal [ answers[0], answers[2] ], [ answers[1], answers[3] ]
  end
end

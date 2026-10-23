# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::FailingSubmissionHandlerTest < ActionDispatch::IntegrationTest
  setup do
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(_submission) { raise "handler failed" })
    @page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.add(@page.document, "form", column_id: column_id))
    @form_id = @page.document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "an error raised in the host's handler is reported through Rails' error reporter with the page and the form's name" do
    reports = []
    subscriber = Object.new.tap { |listener| listener.define_singleton_method(:report) { |error, context:, **| reports << [ error.message, context ] } }
    Rails.error.subscribe(subscriber)

    post address, params: { name: "Ada", email: "ada@example.com" }

    assert_equal [ [ "handler failed", { page_id: @page.id, form_name: "Contact" } ] ], reports.map { |message, context| [ message, context.slice(:page_id, :form_name) ] }
  ensure
    Rails.error.unsubscribe(subscriber)
  end

  test "a visitor whose submission raised an error in the handler sees a message in place of the form saying it was not sent, with their values kept" do
    post address, params: { name: "Ada", email: "ada@example.com" }

    frame = Nokogiri::HTML(response.body).at_css("turbo-frame#keystone-ui-pages-form-#{@form_id}")
    assert_equal [ "Your form was not sent. Please try again.", %w[Ada ada@example.com] ],
      [ frame&.at_css(".ks-alert")&.text&.strip, frame&.css(".ks-form-field input")&.map { |input| input["value"] } ]
  end

  test "a visitor whose submission the handler did not finish receiving never sees the thank-you message and is never sent to the editor's address" do
    answers = [ "thank_you", "address" ].map do |after_submitting|
      document = KeystoneUi::Pages::Operations.set(@page.document, element_id: @form_id, field: "after_submitting", value: after_submitting)
      @page.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: @form_id, field: "next_address", value: "/pages/next-steps"))
      post address, params: { name: "Ada", email: "ada@example.com" }
      [ response.status, response.location, response.body.include?("Thanks, we will be in touch.") ]
    end

    assert_equal [ [ 500, nil, false ] ] * 2, answers
  end

  private

  def address
    @page.publish
    "/pages/contact/versions/#{@page.live_version.number}/forms/#{@form_id}"
  end
end

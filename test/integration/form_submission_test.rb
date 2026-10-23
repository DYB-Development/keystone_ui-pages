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
    KeystoneUi::Pages.view_check_method = nil
    KeystoneUi::Pages.refusal_method = nil
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

  test "two places with two handlers each receive only their own pages' submissions, and either works when the other place is not registered" do
    support = []
    KeystoneUi::Pages.register_place("support", label: "Support", submissions: ->(submission) { support << submission.page.slug })
    KeystoneUi::Pages::Page.create!(name: "Help", slug: "help", place: "support", document: @page.document).publish

    post "/pages/contact/versions/1/forms/#{@form_id}", params: { name: "Ada" }
    post "/pages/help/versions/1/forms/#{@form_id}", params: { name: "Bo" }
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.register_place("support", label: "Support", submissions: ->(submission) { support << submission.page.slug })
    post "/pages/help/versions/1/forms/#{@form_id}", params: { name: "Cy" }

    assert_equal [ [ "contact" ], %w[help help] ], [ @received.map { |submission| submission.page.slug }, support ]
  end

  test "a submission to a form not in the named version is refused as not found" do
    post "/pages/contact/versions/1/forms/not-a-form", params: { name: "Ada" }

    assert_equal [ 404, 0 ], [ response.status, @received.size ]
  end

  test "a submission is refused as not found when its page's place has no handler" do
    KeystoneUi::Pages.register_place("support", label: "Support")
    KeystoneUi::Pages::Page.create!(name: "Help", slug: "help", place: "support", document: @page.document).publish

    post "/pages/help/versions/1/forms/#{@form_id}", params: { name: "Ada" }

    assert_equal [ 404, 0 ], [ response.status, @received.size ]
  end

  test "a submission to a page the visitor may not view is refused the same way the page itself is" do
    KeystoneUi::Pages.view_check_method = :may_view_page?
    KeystoneUi::Pages.refusal_method = :refuse_page

    get "/pages/contact", headers: { "X-Visitor" => "blocked" }
    page_refusal = response.status
    post "/pages/contact/versions/1/forms/#{@form_id}", params: { name: "Ada" }, headers: { "X-Visitor" => "blocked" }

    assert_equal [ page_refusal, 0 ], [ response.status, @received.size ]
  end

  test "a submission is accepted with the token its page was drawn with, and the submission address keeps the host's forgery protection" do
    ActionController::Base.allow_forgery_protection = true

    get "/pages/contact"
    form = Nokogiri::HTML(response.body).at_css("form.ks-form")
    post form["action"], params: { name: "Ada", authenticity_token: form.at_css("input[name=authenticity_token]")["value"] }
    with_token = @received.size
    post form["action"], params: { name: "Bo" }

    assert_equal [ 1, 422, 1 ], [ with_token, response.status, @received.size ]
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end

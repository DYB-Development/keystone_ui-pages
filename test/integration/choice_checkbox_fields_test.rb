# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::ChoiceCheckboxFieldsTest < ActionDispatch::IntegrationTest
  FIELDS = [ { "label" => "Service", "name" => "service", "kind" => "choice", "choices" => "Design, Build, Support", "required" => "true" },
             { "label" => "Contact me", "name" => "consent", "kind" => "checkbox" } ].freeze

  setup do
    @received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", submissions: ->(submission) { @received << submission.values })
    @page = KeystoneUi::Pages::Page.create!(name: "Contact", slug: "contact", place: "marketing")
    column_id = @page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(@page.document, "form", column_id: column_id)
    @form_id = document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page.update!(document: KeystoneUi::Pages::Operations.set(document, element_id: @form_id, field: "fields", value: FIELDS))
    @page.publish
    @address = "/pages/contact/versions/1/forms/#{@form_id}"
  end

  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "a visitor sees a choice field as a menu of the editor's choices and a checkbox field as a checkbox with its label" do
    get "/pages/contact"

    form = Nokogiri::HTML(response.body).at_css("form.ks-form")
    assert_equal [ %w[Design Build Support], "Contact me" ],
      [ form.css("select[name=service] option").map(&:text), form.at_css("input[type=checkbox][name=consent]")&.parent&.text&.strip ]
  end

  test "a submission whose choice value is not one of the field's choices never reaches the host's handler" do
    post @address, params: { service: "Hosting", consent: "0" }

    assert_equal [ 422, 0 ], [ response.status, @received.size ]
  end

  test "the host's handler receives a checkbox field as checked or not checked" do
    [ "1", "0" ].each { |ticked| post @address, params: { service: "Build", consent: ticked } }

    assert_equal [ true, false ], @received.map { |values| values["consent"] }
  end
end

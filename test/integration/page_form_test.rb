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

  test "a required field shows a required marker on the published page and an optional one does not" do
    get "/pages/contact"

    assert_equal [ [ "name", false ], [ "email", true ] ], Nokogiri::HTML(response.body).css(".ks-form-field").map { |field| [ field.at_css("input")["name"], field.at_css(".ks-required").present? ] }
  end

  test "a published form posts to an address naming the version it was drawn from and which form on the page it is" do
    get "/pages/contact"

    assert_equal "/pages/contact/versions/1/forms/#{@form_id}", Nokogiri::HTML(response.body).at_css("form.ks-form")&.[]("action")
  end

  test "each visitor's form carries a forgery token made for that visitor, and the cached drawing holds no visitor's token" do
    cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.allow_forgery_protection = true

    tokens = Array.new(2) do
      visitor = open_session
      visitor.get "/pages/contact"
      Nokogiri::HTML(visitor.response.body).css("form.ks-form input[name=authenticity_token]").map { |input| input["value"] }
    end
    cached = Rails.cache.instance_variable_get(:@data).values.map { |entry| entry.value.to_s }.join

    assert_equal [ [ 1, 1 ], true, false ], [ tokens.map(&:size), tokens.flatten.uniq.size == 2, tokens.flatten.any? { |token| cached.include?(token) } ]
  ensure
    ActionController::Base.allow_forgery_protection = false
    Rails.cache = cache
  end
end

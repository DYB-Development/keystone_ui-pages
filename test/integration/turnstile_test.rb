# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/turnstile"
require "minitest/mock"

class KeystoneUi::Pages::TurnstileTest < ActionDispatch::IntegrationTest
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
    KeystoneUi::Pages.turnstile_site_key = KeystoneUi::Pages.turnstile_secret_key = nil
  end

  test "with keys set, every published form shows Cloudflare's widget at the engine's address and in the host's own view" do
    KeystoneUi::Pages.turnstile_site_key = "site-key"
    KeystoneUi::Pages.turnstile_secret_key = "secret-key"

    shown = [ "/pages/contact", "/products/contact" ].map do |path|
      get path
      html = Nokogiri::HTML(response.body)
      [ html.at_css("form.ks-form .cf-turnstile")&.[]("data-sitekey"), html.css("script[src^='https://challenges.cloudflare.com/turnstile/']").size ]
    end

    assert_equal [ [ "site-key", 1 ] ] * 2, shown
  end

  test "with keys set, a submission whose token Cloudflare does not confirm reaches the host's handler marked as a bot" do
    KeystoneUi::Pages.turnstile_site_key = "site-key"
    KeystoneUi::Pages.turnstile_secret_key = "secret-key"

    KeystoneUi::Pages::Turnstile.stub(:confirmed?, false) do
      post @address, params: { name: "Ada", email: "ada@example.com", "cf-turnstile-response" => "token" }
    end

    assert_equal [ true ], @received.map(&:bot)
  end
end

# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"

class KeystoneUi::Pages::EditorPdfTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme", "acme" ] ] }
    KeystoneUi::Pages::Values.provider = ->(_page, choice) { { "client_name" => choice.capitalize } }
  end

  teardown do
    KeystoneUi::Pages::Values.chooser = nil
    KeystoneUi::Pages::Values.provider = nil
  end

  test "a page that uses no values from the app downloads the PDF made of its public address when it was published" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    printed = []

    KeystoneUi::Pages::Printer.stub(:pdf, ->(_html) { printed << "%PDF-#{printed.size + 1}"; printed.last }) do
      perform_enqueued_jobs { page.publish }
      get "/pages/manage/pages/#{page.id}/pdf"
    end

    assert_equal [ "%PDF-1", [ "%PDF-1" ] ], [ response.body, printed ]
  end
end

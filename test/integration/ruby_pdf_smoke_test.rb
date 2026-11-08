# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "keystone_ui/pages/printer"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::RubyPdfSmokeTest < ActiveSupport::TestCase
  setup { KeystoneUi::Pages.pdf_drawing = :ruby }
  teardown { KeystoneUi::Pages.pdf_drawing = nil }

  test "a host that chooses the Ruby drawing gets a published page as a PDF on a machine with no Chrome, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    page.update!(document: KeystoneUi::Pages::Operations.add(KeystoneUi::Pages::Operations.add(page.document, "heading", column_id: column_id), "label", column_id: column_id))
    page.publish

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "%PDF", pdf.file.download[0, 4]
  end

  test "a host that chooses the Ruby drawing gets a page of paragraphs, alerts and label and value lists as a PDF, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Report", slug: "report")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = %w[paragraph alert value_list].reduce(page.document) { |drawn, key| KeystoneUi::Pages::Operations.add(drawn, key, column_id: column_id) }
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["text"] = { "html" => "<p><strong><em>Firm</em></strong> terms<br>by <a href=\"https://ty-ler.com\">Tyler</a></p>" }
    page.update!(document: document)
    page.publish

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "%PDF", pdf.file.download[0, 4]
  end

  test "a host that chooses the Ruby drawing gets a page of buttons, accordions and a form as a PDF, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Booking", slug: "booking")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = %w[button button accordion form].reduce(page.document) { |drawn, key| KeystoneUi::Pages::Operations.add(drawn, key, column_id: column_id) }
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"]["href"] = "https://ty-ler.com/book"
    page.update!(document: document)
    page.publish

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "%PDF", pdf.file.download[0, 4]
  end

  test "a host that chooses the Ruby drawing gets a page holding a grouped table longer than a page, with its total, as a PDF, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Hours", slug: "hours")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, "data_table", column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"].merge!(
      "items" => Array.new(40) { |index| { "name" => "Review #{index}", "status" => index.even? ? "Open" : "Closed" } },
      "group_by" => "status", "group_totals" => { "Open" => { "status" => "20 open" } }, "total" => { "name" => "Total", "status" => "40" }
    )
    page.update!(document: document)
    page.publish

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "%PDF", pdf.file.download[0, 4]
  end

  test "a host that chooses the Ruby drawing gets a page of stats, figures, badges and progress bars as a PDF, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Numbers", slug: "numbers")
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = %w[stat_card stat_card figure badge progress].reduce(page.document) { |drawn, key| KeystoneUi::Pages::Operations.add(drawn, key, column_id: column_id) }
    document["sections"][0]["rows"][0]["columns"][0]["elements"][1]["fields"].merge!("plain" => "true", "value" => { "value" => "revenue" }, "variant" => "success")
    page.update!(document: document)
    page.publish

    pdf = KeystoneUi::Pages::Printer.stub(:chrome, nil) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "%PDF", pdf.file.download[0, 4]
  end
end

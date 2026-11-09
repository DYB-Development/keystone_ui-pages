# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"
require "keystone_ui/pages/pdf_look"
require "keystone_ui/pages/pdf_drawing"

class KeystoneUi::Pages::HostElementPdfTest < ActiveSupport::TestCase
  QUOTE_DRAWING = ->(surface, fields) { surface.text(fields[:text], size: "--text-base") }

  teardown do
    KeystoneUi::Pages.places = nil
    KeystoneUi::Pages.catalog.leave_out(:quote)
  end

  test "a host element registered with a PDF drawing is drawn in the PDF by that drawing, with its fields filled from the host's values" do
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ], pdf: QUOTE_DRAWING)
    page = page_holding(:quote, { "text" => { "value" => "client_name", "fallback" => "Client" } })

    pdf = KeystoneUi::Pages.pdf(page, values: { "client_name" => "Acme" })

    assert_includes texts(pdf.file.download), "Acme"
  end

  test "a host element's PDF drawing can draw with every call the gem's own element drawings use" do
    cell = ->(text) { { cells: [ { text: text, size: "--text-sm", padding: [ "--ks-spacing", 3, 3, 2 ] } ], fill: "--ks-color-table-body" } }
    drawing = lambda do |surface, fields|
      surface.text(fields[:text], size: "--text-base", color: "--ks-color-text")
      surface.space("--ks-spacing", 2)
      surface.rich_text([ { text: "Rich", bold: true } ], size: "--text-base")
      surface.box(padding: [ "--ks-spacing", 4, 2 ], radius: [ "--ks-radius-surface", 1 ], fill: "--ks-color-overlay", border: { width: "--ks-border-width", color: "--ks-color-border" }) do
        surface.text("Boxed", size: "--text-sm")
      end
      surface.boxed_text("Badge", size: "--text-xs", fill: "--ks-color-badge-neutral", padding: [ "--ks-spacing", 2, 1 ], radius: [ "--ks-radius-pill", 1 ])
      surface.bar(Rational(1, 2), height: [ "--spacing", 2 ], radius: [ "--ks-radius-pill", 1 ], track: "--ks-color-track", fill: "--ks-color-meter")
      surface.rule(width: "--ks-border-width", color: "--ks-color-divider")
      surface.row([ Rational(1, 2), Rational(1, 2) ]) { |index| surface.text(%w[Left Right][index], size: "--text-sm") }
      surface.table(cell.call("Heading"), [ cell.call("Cell") ], border: { width: "--ks-border-width", color: "--ks-color-border" }, radius: [ "--ks-radius-surface", 1 ],
                                                                divider: { width: "--ks-border-width", color: "--ks-color-divider" })
    end
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ], pdf: drawing)

    pdf = KeystoneUi::Pages.pdf(page_holding(:quote, { "text" => "Plain" }), values: {})

    assert_equal %w[Badge Boxed Cell Heading Left Plain Rich Right], texts(pdf.file.download).sort
  end

  test "a host element's PDF drawing that names a keystone_ui colour token draws in the value the host's stylesheet gives that token" do
    drawing = ->(surface, fields) { surface.text(fields[:text], size: "--text-base", color: "--ks-color-accent") }
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ], pdf: drawing)
    accent = KeystoneUi::Pages::PdfLook.host.color("--ks-color-accent").scan(/\h\h/).map { |pair| (pair.to_i(16) / 255.0).round(3) }

    pdf = KeystoneUi::Pages.pdf(page_holding(:quote, { "text" => "Plain" }), values: {})

    assert_includes fill_colors(pdf.file.download), accent
  end

  test "a host element registered without a PDF drawing refuses the PDF with a message naming the element" do
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ])
    page = page_holding(:quote, { "text" => "Plain" })

    error = assert_raises(KeystoneUi::Pages::NoPdfDrawing) { KeystoneUi::Pages.pdf(page, values: {}) }

    assert_equal "The Quote element has no PDF drawing, so this page cannot be drawn as a PDF without Chrome.", error.message
  end

  test "a host element left out of one place's catalog is drawn by its PDF drawing on a page in a place that offers it" do
    KeystoneUi::Pages.catalog.register(key: :quote, name: "Quote", component: :ui_paragraph, fields: [ { key: :text, label: "Text", default: "Hi" } ], pdf: QUOTE_DRAWING)
    KeystoneUi::Pages.register_place("client_report", label: "Client report", leaves_out: [ :quote ])
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site")

    pdf = KeystoneUi::Pages.pdf(page_holding(:quote, { "text" => "Offered" }, place: "marketing"), values: {})

    assert_includes texts(pdf.file.download), "Offered"
  end

  private

  def fill_colors(pdf)
    pdf.scan(/([\d.]+) ([\d.]+) ([\d.]+) scn/).map { |rgb| rgb.map { |part| part.to_f.round(3) } }
  end

  def page_holding(key, fields, place: nil)
    page = KeystoneUi::Pages::Page.create!(name: "Report", slug: "report", place: place)
    column_id = page.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages::Operations.add(page.document, key.to_s, column_id: column_id)
    document["sections"][0]["rows"][0]["columns"][0]["elements"][0]["fields"].merge!(fields)
    page.update!(document: document)
    page.publish
    page
  end

  def texts(pdf)
    pdf.scan(/\[([^\]]*)\] TJ/).flatten.map { |kerned| kerned.scan(/<(\h+)>/).flatten.join.then { |text| [ text ].pack("H*") } }
  end
end

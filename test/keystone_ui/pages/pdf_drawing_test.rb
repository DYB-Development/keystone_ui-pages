# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/pdf_drawing"

class KeystoneUi::Pages::PdfDrawingTest < ActiveSupport::TestCase
  class RecordingSurface
    attr_reader :drawn

    def initialize
      @drawn = []
    end

    def text(content, size:)
      @drawn << [ :text, content, size ]
    end

    def row(widths)
      @drawn << [ :row, widths ]
      widths.each_index { |index| yield index }
    end

    def texts
      @drawn.select { |call| call.first == :text }.map { |call| call[1] }
    end
  end

  test "the PDF draws each heading and label in the order the page shows them" do
    document = page(
      section(row(column(element("heading", text: "Pricing"), element("label", text: "Per seat")))),
      section(row(column(element("label", text: "Billed monthly"))))
    )

    assert_equal [ "Pricing", "Per seat", "Billed monthly" ], drawn(document).texts
  end

  test "a row's columns are drawn side by side at the widths the page gives them on a wide screen" do
    document = page(section(row(column(wide: "1/4"), column)))

    assert_equal [ :row, [ Rational(1, 4), Rational(1, 2) ] ], drawn(document).drawn.first
  end

  test "a heading or label bound to a host value shows that value, or its fallback when the value is missing" do
    document = page(section(row(column(element("heading", text: { "value" => "client_name", "fallback" => "Client" }),
                                       element("label", text: { "value" => "plan_name", "fallback" => "Your plan" })))))

    assert_equal [ "Acme", "Your plan" ], drawn(document, values: { "client_name" => "Acme" }).texts
  end

  test "a section, row or element hidden by its condition for the values given is left out of the PDF" do
    internal = { "value" => "audience", "equals" => "internal" }
    document = page(
      section(row(column(element("label", text: "Hidden section"))), show_when: internal),
      section(row(column(element("label", text: "Hidden row")), show_when: internal),
              row(column(element("label", text: "Hidden element", show_when: internal), element("label", text: "Shown"))))
    )

    assert_equal [ "Shown" ], drawn(document, values: { "audience" => "public" }).texts
  end

  private

  def drawn(document, values: {})
    RecordingSurface.new.tap { |surface| KeystoneUi::Pages::PdfDrawing.draw(document, surface, values: values) }
  end

  def page(*sections)
    { "schema_version" => 1, "sections" => sections }
  end

  def section(*rows, **settings)
    { "id" => SecureRandom.uuid, "rows" => rows }.merge(settings.stringify_keys)
  end

  def row(*columns, **settings)
    { "id" => SecureRandom.uuid, "columns" => columns }.merge(settings.stringify_keys)
  end

  def column(*elements, **settings)
    { "id" => SecureRandom.uuid, "elements" => elements }.merge(settings.stringify_keys)
  end

  def element(key, show_when: nil, **fields)
    { "id" => SecureRandom.uuid, "key" => key, "fields" => fields.stringify_keys, "show_when" => show_when }.compact
  end
end

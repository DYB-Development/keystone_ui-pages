# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/document"

class KeystoneUi::Pages::DrawingHelperTest < ActionView::TestCase
  helper KeystoneUiHelper
  include KeystoneUi::Pages::DrawingHelper

  setup do
    @document = KeystoneUi::Pages::Document.blank
  end

  test "a section is drawn with keystone_ui's class for its spacing" do
    @document["sections"][0]["spacing"] = "lg"

    render html: drawn_document(@document)

    assert_select "section.ks-pages-section.ks-section-lg"
  end

  test "a row is drawn as a twelve-column grid with keystone_ui's class for its gap" do
    @document["sections"][0]["rows"][0]["gap"] = "xl"

    render html: drawn_document(@document)

    assert_select "div.ks-pages-row.grid.grid-cols-12.ks-grid-gap-xl"
  end
end

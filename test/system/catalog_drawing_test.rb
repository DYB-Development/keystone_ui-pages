# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::CatalogDrawingTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "every element in the catalog is drawn in the builder by the same component with the same classes as on the live page" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Everything", slug: "everything")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = KeystoneUi::Pages.catalog.elements.reduce(page_record.document) do |filled, element|
      KeystoneUi::Pages::Operations.add(filled, element.key, column_id: column_id)
    end
    page_record.update!(document: document)
    page_record.publish
    visit "/pages/manage/pages/#{page_record.id}"
    built = drawn_elements

    visit "/pages/everything"

    assert_equal built, drawn_elements
  end

  private

  def drawn_elements
    assert_selector ".ks-pages-element", visible: :all, count: KeystoneUi::Pages.catalog.elements.size
    all(".ks-pages-element", visible: :all).map { |element| element[:innerHTML] }
  end
end

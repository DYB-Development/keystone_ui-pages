# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::AlignmentLivePageTest < KeystoneUi::Pages::ApplicationSystemTestCase
  test "the live page shows each element with the alignment it has in the builder" do
    page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    document = %w[button card badge].reduce(page_record.document) { |filled, key| KeystoneUi::Pages::Operations.add(filled, key, column_id: column_id) }
    page_record.update!(document: document)
    visit "/pages/manage/pages/#{page_record.id}"
    built = all("[data-element-id]").map { |element| element[:class] }
    page_record.publish

    visit "/pages/pricing"

    assert_equal built, all(".ks-pages-element").map { |element| element[:class] }
  end
end

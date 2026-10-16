# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::PageEditHistoryTest < ActiveSupport::TestCase
  setup do
    @page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    @blank = @page.document
    column_id = @blank["sections"][0]["rows"][0]["columns"][0]["id"]
    @with_button = KeystoneUi::Pages::Operations.add(@blank, "button", column_id: column_id)
  end

  test "undoing an edit returns the page to the document it had before that edit" do
    @page.edit(@with_button)

    @page.undo

    assert_equal @blank, @page.reload.document
  end

  test "redoing an undone edit puts that edit back" do
    @page.edit(@with_button)
    @page.undo

    @page.redo

    assert_equal @with_button, @page.reload.document
  end

  test "a new edit after undoing clears what can be redone" do
    @page.edit(@with_button)
    @page.undo

    @page.edit(@with_button)

    assert_equal [], @page.reload.undone_changes
  end

  test "each edit is its own undo step" do
    column_id = @blank["sections"][0]["rows"][0]["columns"][0]["id"]
    with_two = KeystoneUi::Pages::Operations.add(@with_button, "button", column_id: column_id)
    with_three = KeystoneUi::Pages::Operations.add(with_two, "button", column_id: column_id)
    [ @with_button, with_two, with_three ].each { |document| @page.edit(document) }

    2.times { @page.undo }

    assert_equal @with_button, @page.reload.document
  end
end

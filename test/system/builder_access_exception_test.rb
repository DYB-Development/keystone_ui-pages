# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::BuilderAccessExceptionTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    KeystoneUi::Pages.access_exceptions = { "public_preview" => "Public preview" }
    @page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
  end

  teardown do
    KeystoneUi::Pages.access_exceptions = nil
  end

  test "an editor chooses a page's access exception in the builder" do
    visit "/pages/manage/pages/#{@page_record.id}"

    select "Public preview", from: "Access exception"

    assert_equal "public_preview", saved_access_exception("public_preview")
  end

  test "an editor clears a page's access exception in the builder" do
    @page_record.update!(access_exception: "public_preview")
    visit "/pages/manage/pages/#{@page_record.id}"

    select "None", from: "Access exception"

    assert_nil saved_access_exception(nil)
  end

  test "the builder offers no access exception when the host names none" do
    KeystoneUi::Pages.access_exceptions = nil
    visit "/pages/manage/pages/#{@page_record.id}"

    find("[data-builder-top-bar]")
    assert_no_text "Access exception"
  end

  private

  def saved_access_exception(expected)
    page.document.synchronize { raise Capybara::ExpectationNotMet unless @page_record.reload.access_exception == expected }
    @page_record.access_exception
  rescue Capybara::ExpectationNotMet
    @page_record.access_exception
  end
end

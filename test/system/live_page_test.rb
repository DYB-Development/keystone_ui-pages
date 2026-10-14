# frozen_string_literal: true

require "application_system_test_case"
require "keystone_ui/pages/operations"

class KeystoneUi::Pages::LivePageTest < KeystoneUi::Pages::ApplicationSystemTestCase
  setup do
    @page_record = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    column_id = @page_record.document["sections"][0]["rows"][0]["columns"][0]["id"]
    added = KeystoneUi::Pages::Operations.add(@page_record.document, "button", column_id: column_id)
    element_id = added["sections"][0]["rows"][0]["columns"][0]["elements"][0]["id"]
    @page_record.update!(document: KeystoneUi::Pages::Operations.set(added, element_id: element_id, field: "label", value: "Get a quote"))
    @page_record.publish
  end

  test "a page's address shows its live version drawn with keystone_ui components inside the host's layout" do
    visit "/pages/pricing"

    assert_selector "[data-host-layout] .ks-button", text: "Get a quote"
  end

  test "a live page draws its button in the host's accent colour" do
    visit "/pages/pricing"

    assert_equal color_of_variable("--ks-color-accent"), page.evaluate_script("getComputedStyle(document.querySelector('.ks-button')).backgroundColor")
  end

  private

  def color_of_variable(name)
    page.evaluate_script(<<~JS)
      (() => {
        const probe = document.createElement("div")
        probe.style.backgroundColor = "var(#{name})"
        document.body.appendChild(probe)
        const color = getComputedStyle(probe).backgroundColor
        probe.remove()
        return color
      })()
    JS
  end
end

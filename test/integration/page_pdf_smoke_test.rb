# frozen_string_literal: true

require "test_helper"
require "selenium-webdriver"

class KeystoneUi::Pages::PagePdfSmokeTest < ActiveSupport::TestCase
  setup { KeystoneUi::Pages.chrome_path = ENV["CHROME_BIN"].presence || Selenium::WebDriver::SeleniumManager.binary_paths("--browser", "chrome")["browser_path"] }
  teardown { KeystoneUi::Pages.chrome_path = nil }

  test "a host gets a published page as a PDF printed by Chrome, end to end" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")
    page.publish

    assert_equal "%PDF", KeystoneUi::Pages.pdf(page, values: {}).file.download[0, 4]
  end
end

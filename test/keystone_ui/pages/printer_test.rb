# frozen_string_literal: true

require "test_helper"
require "selenium-webdriver"
require "keystone_ui/pages/printer"

class KeystoneUi::Pages::PrinterTest < Minitest::Test
  def setup
    KeystoneUi::Pages.chrome_path = ENV["CHROME_BIN"].presence || Selenium::WebDriver::SeleniumManager.binary_paths("--browser", "chrome")["browser_path"]
  end

  def teardown
    KeystoneUi::Pages.chrome_path = nil
  end

  def test_prints_html_to_a_pdf_with_chrome
    pdf = KeystoneUi::Pages::Printer.pdf("<!doctype html><html><body><h1>Acme monthly report</h1></body></html>")

    assert_equal "%PDF", pdf[0, 4]
  end
end

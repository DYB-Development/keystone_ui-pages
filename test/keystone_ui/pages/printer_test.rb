# frozen_string_literal: true

require "test_helper"
require "selenium-webdriver"
require "minitest/mock"
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

  def test_says_which_chrome_failed_when_it_cannot_print
    KeystoneUi::Pages.chrome_path = "/no/such/chrome"

    error = assert_raises(KeystoneUi::Pages::PrintFailed) { KeystoneUi::Pages::Printer.pdf("<p>Hi</p>") }

    assert_includes error.message, "/no/such/chrome"
  end

  def test_uses_the_chrome_named_by_chrome_bin_when_no_path_is_set
    KeystoneUi::Pages.chrome_path = nil
    original = ENV["CHROME_BIN"]
    ENV["CHROME_BIN"] = "/opt/chrome/chrome"

    assert_equal "/opt/chrome/chrome", KeystoneUi::Pages::Printer.chrome
  ensure
    ENV["CHROME_BIN"] = original
  end

  def test_finds_chromium_in_its_usual_place_when_nothing_names_chrome
    KeystoneUi::Pages.chrome_path = nil
    original = ENV.delete("CHROME_BIN")

    found = File.stub(:executable?, ->(place) { place == "/usr/bin/chromium" }) { KeystoneUi::Pages::Printer.chrome }

    assert_equal "/usr/bin/chromium", found
  ensure
    ENV["CHROME_BIN"] = original
  end
end

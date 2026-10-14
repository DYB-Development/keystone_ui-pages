# frozen_string_literal: true

require "test_helper"
require "capybara/rails"
require "selenium-webdriver"

module KeystoneUi
  module Pages
    class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
      CACHED_CHROME = Dir[File.expand_path("~/.cache/selenium/chrome/*/*/*.app/Contents/MacOS/Google Chrome for Testing")].max

      driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
        chrome = ENV["CHROME_BIN"].presence || CACHED_CHROME
        options.binary = chrome if chrome
      end
    end
  end
end

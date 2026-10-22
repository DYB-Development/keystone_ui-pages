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

      def wait_for
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Capybara.default_max_wait_time
        sleep 0.05 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        yield
      end

      def touched(source, target)
        actions = page.driver.browser.action
        finger = actions.add_pointer_input(:touch, "finger")
        actions
          .move_to(source.native, device: "finger").pointer_down(:left, device: "finger").pause(device: finger, duration: 0.3)
          .move_by(10, 10, device: "finger").pause(device: finger, duration: 0.1)
          .move_to(target.native, device: "finger").pause(device: finger, duration: 0.1)
          .pointer_up(:left, device: "finger").perform
      end
    end
  end
end

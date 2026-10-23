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

      def with_event_address_blocked
        page.driver.browser.execute_cdp("Network.enable")
        page.driver.browser.execute_cdp("Network.setBlockedURLs", urls: [ "*/events" ])
        yield
      ensure
        page.driver.browser.execute_cdp("Network.setBlockedURLs", urls: [])
      end

      def dragged(source, target)
        page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", source)
        page.driver.browser.action
          .click_and_hold(source.native).move_by(10, 10).pause(duration: 0.1)
          .move_to(target.native).pause(duration: 0.1).move_by(2, 2).pause(duration: 0.1)
          .release.perform
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

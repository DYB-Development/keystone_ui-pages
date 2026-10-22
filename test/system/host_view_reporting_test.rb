# frozen_string_literal: true

require "application_system_test_case"

class KeystoneUi::Pages::HostViewReportingTest < KeystoneUi::Pages::ApplicationSystemTestCase
  teardown do
    KeystoneUi::Pages.places = nil
  end

  test "opening a host view that draws the live version of a page whose place has a handler calls that handler once with a view" do
    received = []
    KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { received << event.kind })
    KeystoneUi::Pages::Page.create!(name: "Product", slug: "product", place: "marketing").publish

    visit "/products/product"

    assert_equal [ "view" ], wait_for { received.dup.presence }
  end

  private

  def wait_for
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Capybara.default_max_wait_time
    sleep 0.05 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    yield
  end
end

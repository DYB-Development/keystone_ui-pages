# frozen_string_literal: true

require "test_helper"
require "keystone_ui/pages/turnstile"
require "minitest/mock"

class KeystoneUi::Pages::TurnstileCheckTest < ActiveSupport::TestCase
  teardown do
    KeystoneUi::Pages.turnstile_secret_key = nil
  end

  test "confirming a token sends the secret key, the token and the visitor's address to Cloudflare and reads its answer" do
    KeystoneUi::Pages.turnstile_secret_key = "secret-key"
    sent = []
    answer = Struct.new(:body).new('{"success":true}')

    confirmed = Net::HTTP.stub(:post_form, ->(address, fields) { sent << [ address.to_s, fields ] && answer }) do
      KeystoneUi::Pages::Turnstile.confirmed?("token", "203.0.113.5")
    end

    assert_equal [ true, [ [ "https://challenges.cloudflare.com/turnstile/v0/siteverify", { secret: "secret-key", response: "token", remoteip: "203.0.113.5" } ] ] ], [ confirmed, sent ]
  end
end

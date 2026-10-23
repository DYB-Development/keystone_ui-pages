# frozen_string_literal: true

require "json"
require "net/http"

module KeystoneUi
  module Pages
    module Turnstile
      VERIFY_ADDRESS = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")

      module_function

      def on?
        Pages.turnstile_site_key.present? && Pages.turnstile_secret_key.present?
      end

      def confirmed?(token, remote_ip)
        answer = Net::HTTP.post_form(VERIFY_ADDRESS, secret: Pages.turnstile_secret_key, response: token.to_s, remoteip: remote_ip.to_s)
        JSON.parse(answer.body)["success"] == true
      rescue StandardError
        false
      end
    end
  end
end

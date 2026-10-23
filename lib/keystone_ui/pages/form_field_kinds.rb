# frozen_string_literal: true

require "uri"

module KeystoneUi
  module Pages
    module FormFieldKinds
      Kind = Data.define(:drawn_as, :limit, :check, :delivered)

      KINDS = {
        "text" => Kind.new(drawn_as: :text, limit: 200, check: nil, delivered: nil),
        "email" => Kind.new(drawn_as: :email, limit: 254, delivered: nil,
          check: ->(value, _field) { "Enter an email address" unless value.match?(URI::MailTo::EMAIL_REGEXP) }),
        "long_text" => Kind.new(drawn_as: :textarea, limit: 5000, check: nil, delivered: nil),
        "choice" => Kind.new(drawn_as: :select, limit: 200, delivered: nil,
          check: ->(value, field) { "Choose one of the options" unless FormFieldKinds.choices(field["choices"]).include?(value) }),
        "checkbox" => Kind.new(drawn_as: :checkbox, limit: 1, check: nil, delivered: ->(value) { value.to_s == "1" })
      }.freeze

      module_function

      def keys
        KINDS.keys
      end

      def find(key)
        KINDS.fetch(key.to_s.presence || "text", KINDS["text"])
      end

      def choices(text)
        text.to_s.split(",").map(&:strip).reject(&:empty?)
      end
    end
  end
end

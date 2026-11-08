# frozen_string_literal: true

module KeystoneUi
  module Pages
    Sequence = Data.define(:title, :pages, :back_url, :screen_url, :end_label) do
      def initialize(title:, pages:, back_url:, screen_url: nil, end_label: nil)
        super
      end
    end
    SequencePublishRefused = Class.new(StandardError)
  end
end

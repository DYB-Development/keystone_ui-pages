# frozen_string_literal: true

require "keystone_ui/pages/document"

module KeystoneUi
  module Pages
    class Page < ActiveRecord::Base
      self.table_name = "keystone_ui_pages_pages"

      belongs_to :owner, polymorphic: true, optional: true
      has_many :versions, -> { order(:number) }, class_name: "KeystoneUi::Pages::Version", dependent: :destroy, inverse_of: :page

      attribute :document, :json, default: -> { Document.blank }

      validates :name, :slug, presence: true

      def publish
        transaction do
          live_version&.update!(status: :superseded)
          versions.create!(number: next_number, document: document, status: :live)
        end.tap { PdfJob.perform_later(self, {}) unless uses_host_values? }
      end

      def uses_host_values?(node = document)
        case node
        when Hash then node.key?("show_when") || (node.key?("value") && node.key?("fallback")) || node.values.any? { |child| uses_host_values?(child) }
        when Array then node.any? { |child| uses_host_values?(child) }
        else false
        end
      end

      def live_version
        versions.find_by(status: :live)
      end

      def next_number
        (versions.maximum(:number) || 0) + 1
      end
    end
  end
end

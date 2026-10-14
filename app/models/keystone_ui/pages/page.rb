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
          versions.create!(number: next_number, document: document, status: :live)
        end
      end

      def next_number
        (versions.maximum(:number) || 0) + 1
      end
    end
  end
end

# frozen_string_literal: true

require "securerandom"
require "keystone_ui/pages/document"

module KeystoneUi
  module Pages
    class Page < ActiveRecord::Base
      self.table_name = "keystone_ui_pages_pages"

      belongs_to :owner, polymorphic: true, optional: true
      has_many :versions, -> { order(:number) }, class_name: "KeystoneUi::Pages::Version", dependent: :destroy, inverse_of: :page

      attribute :document, :json, default: -> { Document.blank }
      attribute :undo_history, :json, default: -> { [] }
      attribute :undone_changes, :json, default: -> { [] }

      scope :archived, -> { where.not(archived_at: nil) }
      scope :current, -> { where(archived_at: nil) }

      before_validation(on: :create) do
        self.name = default_name if name.blank?
        self.slug = SecureRandom.hex(4) if slug.blank?
      end

      validates :name, :slug, presence: true
      validates :slug, uniqueness: { scope: %i[owner_type owner_id] }
      validates :place, inclusion: { in: -> { KeystoneUi::Pages.places.keys } }, if: -> { KeystoneUi::Pages.places.any? }
      validates :access_exception, inclusion: { in: -> { KeystoneUi::Pages.access_exceptions.keys } }, allow_nil: true, if: -> { KeystoneUi::Pages.access_exceptions.any? }

      def publish
        return if archived_at

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

      def edit(changed_document)
        update!(document: changed_document, undo_history: undo_history + [ document ], undone_changes: [])
      end

      def undo
        update!(document: undo_history.last, undo_history: undo_history[0...-1], undone_changes: undone_changes + [ document ])
      end

      def redo
        update!(document: undone_changes.last, undone_changes: undone_changes[0...-1], undo_history: undo_history + [ document ])
      end

      def unpublish
        live_version&.update!(status: :superseded)
      end

      def archive
        transaction do
          unpublish
          update!(archived_at: Time.current)
        end
      end

      def restore
        update!(archived_at: nil)
      end

      def state
        return :archived if archived_at
        return :published if live_version
        return :unpublished if versions.exists?

        :draft
      end

      def live_version
        versions.find_by(status: :live)
      end

      def reporting?
        live_version.present? && KeystoneUi::Pages.reported?(place)
      end

      def next_number
        (versions.maximum(:number) || 0) + 1
      end

      def default_name
        word = KeystoneUi::Pages.place_settings.dig(place, :default_name) || "Page"
        used = Page.where(owner: owner, place: place).pluck(:name).filter_map { |taken| taken[/\A#{Regexp.escape(word)} (\d+)\z/, 1]&.to_i }
        "#{word} #{(used.max || 0) + 1}"
      end
    end
  end
end

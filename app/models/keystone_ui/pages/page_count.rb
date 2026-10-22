# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PageCount < ActiveRecord::Base
      self.table_name = "keystone_ui_pages_page_counts"

      belongs_to :page, class_name: "KeystoneUi::Pages::Page", inverse_of: :counts

      def self.add(page, kind)
        count = page.counts.create_or_find_by!(day: Date.current, kind: kind)
        update_counters(count.id, total: 1)
      end
    end
  end
end

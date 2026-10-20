# frozen_string_literal: true

module KeystoneUi
  module Pages
    class Version < ActiveRecord::Base
      self.table_name = "keystone_ui_pages_versions"

      enum :status, { live: "live", superseded: "superseded" }

      belongs_to :page, class_name: "KeystoneUi::Pages::Page", inverse_of: :versions

      def title
        document["title"]
      end
    end
  end
end

# frozen_string_literal: true

module KeystoneUi
  module Pages
    class Pdf < ActiveRecord::Base
      self.table_name = "keystone_ui_pages_pdfs"

      belongs_to :version, class_name: "KeystoneUi::Pages::Version"
      has_one_attached :file
    end
  end
end

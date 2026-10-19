# frozen_string_literal: true

class AddArchivedAtToKeystoneUiPagesPages < ActiveRecord::Migration[7.1]
  def change
    add_column :keystone_ui_pages_pages, :archived_at, :datetime
  end
end

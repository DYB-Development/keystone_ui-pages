# frozen_string_literal: true

class AddEditHistoryToKeystoneUiPagesPages < ActiveRecord::Migration[7.1]
  def change
    add_column :keystone_ui_pages_pages, :undo_history, :json
  end
end

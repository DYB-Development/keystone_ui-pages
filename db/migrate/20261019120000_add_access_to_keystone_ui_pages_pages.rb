# frozen_string_literal: true

class AddAccessToKeystoneUiPagesPages < ActiveRecord::Migration[7.1]
  def change
    add_column :keystone_ui_pages_pages, :place, :string
    add_column :keystone_ui_pages_pages, :access_exception, :string
  end
end

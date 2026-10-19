# frozen_string_literal: true

class AddAccessToKeystoneUiPagesPages < ActiveRecord::Migration[7.1]
  def change
    add_column :keystone_ui_pages_pages, :place, :string
  end
end

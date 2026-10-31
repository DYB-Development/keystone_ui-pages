# frozen_string_literal: true

class AddSequenceKeyToKeystoneUiPagesPages < ActiveRecord::Migration[7.1]
  def change
    add_column :keystone_ui_pages_pages, :sequence_key, :string
  end
end

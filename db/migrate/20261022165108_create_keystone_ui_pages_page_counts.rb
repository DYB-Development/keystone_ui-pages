# frozen_string_literal: true

class CreateKeystoneUiPagesPageCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :keystone_ui_pages_page_counts do |t|
      t.references :page, null: false, foreign_key: { to_table: :keystone_ui_pages_pages }
      t.date :day, null: false
      t.string :kind, null: false
      t.integer :total, null: false, default: 0

      t.timestamps
    end

    add_index :keystone_ui_pages_page_counts, [ :page_id, :day, :kind ], unique: true, name: "index_keystone_ui_pages_page_counts_on_page_day_kind"
  end
end

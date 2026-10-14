# frozen_string_literal: true

class CreateKeystoneUiPagesVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :keystone_ui_pages_versions do |t|
      t.references :page, null: false, foreign_key: { to_table: :keystone_ui_pages_pages }
      t.integer :number, null: false
      t.json :document, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :keystone_ui_pages_versions, [ :page_id, :number ], unique: true
    add_index :keystone_ui_pages_versions, :page_id, unique: true, where: "status = 'live'",
      name: "index_keystone_ui_pages_versions_on_one_live_per_page"
  end
end

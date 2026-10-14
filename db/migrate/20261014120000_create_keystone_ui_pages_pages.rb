# frozen_string_literal: true

class CreateKeystoneUiPagesPages < ActiveRecord::Migration[7.1]
  def change
    create_table :keystone_ui_pages_pages do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.json :document, null: false
      t.references :owner, polymorphic: true

      t.timestamps
    end

    add_index :keystone_ui_pages_pages, [ :owner_type, :owner_id, :slug ], unique: true,
      name: "index_keystone_ui_pages_pages_on_owner_and_slug"
  end
end

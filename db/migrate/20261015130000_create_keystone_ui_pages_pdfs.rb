# frozen_string_literal: true

class CreateKeystoneUiPagesPdfs < ActiveRecord::Migration[7.1]
  def change
    create_table :keystone_ui_pages_pdfs do |t|
      t.references :version, null: false, foreign_key: { to_table: :keystone_ui_pages_versions }
      t.string :values_digest, null: false

      t.timestamps
    end

    add_index :keystone_ui_pages_pdfs, [ :version_id, :values_digest ], unique: true
  end
end

class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :guest_password_digest
      t.integer :guest_access_version, null: false, default: 1

      t.timestamps
    end
  end
end

class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.string :title, null: false
      t.string :artist, null: false
      t.string :title_key, null: false, index: true
      t.string :status, null: false, default: "maybe"
      t.text :sheet
      t.string :sheet_format, null: false, default: "chordpro"
      t.string :written_key
      t.integer :written_capo, null: false, default: 0
      t.string :house_key
      t.boolean :key_guessed, null: false, default: false
      t.text :notes
      t.string :ug_url
      t.string :ug_type
      t.boolean :needs_paste, null: false, default: false
      t.string :listen_url

      t.timestamps
    end
  end
end

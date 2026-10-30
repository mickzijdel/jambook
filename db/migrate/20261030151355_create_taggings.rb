class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.references :song, null: false, foreign_key: true, index: false # covered by the unique index below
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :taggings, %i[ song_id tag_id ], unique: true
  end
end

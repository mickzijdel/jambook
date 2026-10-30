class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :current_song, foreign_key: { to_table: :songs, on_delete: :nullify }
      t.string :room_key

      t.timestamps
    end
  end
end

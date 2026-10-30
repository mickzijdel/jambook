# The one live room: which song is playing and the key it sounds in. Guests' pages follow it.
class Room < ApplicationRecord
  belongs_to :current_song, class_name: "Song", optional: true

  # Synchronous on purpose: _later broadcasts go through Active Job (spec §6.4 gotcha 2).
  after_update_commit :broadcast_refresh

  def self.instance
    first_or_create!
  end

  def play(song)
    update!(current_song: song, room_key: song.house_key)
  end

  def transpose(delta)
    transaction do
      update!(room_key: MusicKey.transpose(room_key, delta))
      current_song&.update!(house_key: room_key)
    end
  end
end

# Edits to the playing song reach every guest following the room.
module Song::Broadcastable
  extend ActiveSupport::Concern

  included do
    # One callback: commit callbacks that share a method name override each other.
    after_commit :refresh_room, on: %i[ update destroy ], if: :guests_see_change?
  end

  def playing?
    Room.instance.current_song_id == id
  end

  private
    # A deleted song empties the room in the database (on_delete: :nullify), skipping Room's own callback.
    def guests_see_change?
      destroyed? || ((saved_change_to_notes? || saved_change_to_sheet?) && playing?)
    end

    def refresh_room
      Room.instance.broadcast_refresh
    end
end

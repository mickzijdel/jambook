require "test_helper"

class Song::BroadcastableTest < ActiveSupport::TestCase
  test "note edits on the playing song refresh guests" do
    room = Room.instance.tap { it.play(songs(:amazing_grace)) }

    assert_turbo_stream_broadcasts(room, count: 1) { songs(:amazing_grace).update!(notes: "Slow outro") }
  end

  test "note edits on other songs stay quiet" do
    room = Room.instance.tap { it.play(songs(:amazing_grace)) }

    # capture, not assert_no_turbo_stream_broadcasts: that one also counts the play broadcast above.
    assert_empty capture_turbo_stream_broadcasts(room) { songs(:rising_sun).update!(notes: "x") }
  end

  test "deleting the playing song empties the room and refreshes guests" do
    room = Room.instance.tap { it.play(songs(:amazing_grace)) }

    assert_turbo_stream_broadcasts(room, count: 1) { songs(:amazing_grace).destroy! }
    assert_nil room.reload.current_song
  end
end

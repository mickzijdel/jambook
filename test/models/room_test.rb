require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "play takes the song's house key" do
    Room.instance.play(songs(:amazing_grace))

    assert_equal "A", Room.instance.room_key
  end

  test "transpose moves the key and broadcasts" do
    room = Room.instance.tap { it.play(songs(:amazing_grace)) }

    assert_turbo_stream_broadcasts(room, count: 1) { room.transpose(1) }
    assert_equal "Bb", room.room_key
  end

  test "transpose remembers the key on the song" do
    Room.instance.tap { it.play(songs(:amazing_grace)) }.transpose(1)

    assert_equal "Bb", songs(:amazing_grace).reload.house_key
  end
end

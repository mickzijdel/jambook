require "test_helper"

class Rooms::KeysControllerTest < ActionDispatch::IntegrationTest
  setup { Room.instance.play(songs(:amazing_grace)) }

  test "the host moves the key one step" do
    sign_in_as_host
    patch room_key_path(delta: 1)

    assert_equal "Bb", Room.instance.room_key
  end

  test "the key moves one step at a time" do
    sign_in_as_host
    patch room_key_path(delta: 5)

    assert_response :unprocessable_entity
  end
end

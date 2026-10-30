require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "empty room tells guests nothing is playing" do
    enter_guest_password
    get root_path

    assert_select "h1", "Nothing playing yet"
  end

  test "the room shows the playing song in the room key" do
    Room.instance.play(songs(:amazing_grace))
    enter_guest_password
    get root_path

    assert_select "h1", "Amazing Grace – John Newton"
    assert_select "#sheet[data-chord-sheet-key-value=?]", "A"
  end

  test "pages refresh by morphing" do
    enter_guest_password
    get root_path

    assert_select "meta[name=turbo-refresh-method][content=morph]"
  end
end

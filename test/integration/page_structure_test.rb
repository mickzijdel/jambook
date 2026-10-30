require "test_helper"

# What a screen reader needs on every page: the language, one main landmark, and the
# now-playing banner (pinned to the bottom of the screen) after the content in reading order.
class PageStructureTest < ActionDispatch::IntegrationTest
  test "a page names its language and has one main landmark" do
    get new_guest_access_path

    assert_select "html[lang=en]"
    assert_select "main", count: 1
  end

  test "the now-playing banner comes after the content" do
    Room.instance.play(songs(:amazing_grace))
    enter_guest_password
    get songs_path

    assert_select "main + .banner"
  end
end

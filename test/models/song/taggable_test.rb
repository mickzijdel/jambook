require "test_helper"

class Song::TaggableTest < ActiveSupport::TestCase
  test "tag names round-trip and scope" do
    songs(:rising_sun).update!(tag_names: "friend-standard, went-well")

    assert_equal %w[friend-standard went-well], songs(:rising_sun).reload.tag_names.sort
    assert_includes Song.tagged("went-well"), songs(:rising_sun)
  end
end

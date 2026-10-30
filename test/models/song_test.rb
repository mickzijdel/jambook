require "test_helper"

class SongTest < ActiveSupport::TestCase
  test "a song needs a title and an artist" do
    refute_predicate Song.new(title: "", artist: ""), :valid?
  end

  test "a song needs a title that leaves a match key" do
    refute_predicate Song.new(title: "!!!", artist: "A"), :valid?
  end

  test "a song is playable once it has a sheet and a key" do
    assert_predicate songs(:amazing_grace), :playable?
    refute_predicate songs(:no_key), :playable?
  end
end

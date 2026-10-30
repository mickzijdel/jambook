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

  test "links must be web addresses" do
    refute_predicate Song.new(title: "T", artist: "A", listen_url: "javascript:alert(1)"), :valid?
    refute_predicate Song.new(title: "T", artist: "A", ug_url: "data:text/html,hi"), :valid?
    assert_predicate Song.new(title: "T", artist: "A", ug_url: "https://tabs.ultimate-guitar.com/tab/x"), :valid?
  end
end

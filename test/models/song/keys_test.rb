require "test_helper"

class Song::KeysTest < ActiveSupport::TestCase
  test "a missing key is guessed from the sheet" do
    song = Song.create!(title: "T", artist: "A", sheet: "[Em]la [G]la", written_capo: 2)

    assert_equal "Em", song.written_key
    assert song.key_guessed
  end

  test "the house key is the sounding key" do
    song = Song.create!(title: "T", artist: "A", sheet: "[Em]la", written_capo: 2)

    assert_equal "F#m", song.house_key
  end

  test "keys are stored in the house spelling" do
    song = Song.create!(title: "T", artist: "A", sheet: "[G]la", written_key: "D#m")

    assert_equal "Ebm", song.written_key
  end

  test "a capo outside 0 to 11 is invalid" do
    refute_predicate Song.new(title: "T", artist: "A", written_capo: 12), :valid?
  end
end

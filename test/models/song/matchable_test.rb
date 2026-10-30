require "test_helper"

class Song::MatchableTest < ActiveSupport::TestCase
  test "title keys survive spacing and number words" do
    assert_equal Song.title_key("Day Tripper"), Song.title_key("Daytripper")
    assert_equal Song.title_key("Seven Nation Army"), Song.title_key("7 Nation Army")
  end

  test "title keys survive abbreviations and spelling" do
    assert_equal Song.title_key("King of Carrot Flowers Pt. 1"), Song.title_key("King of Carrot Flowers Part 1")
    assert_equal Song.title_key("In the Aeroplane Over the Sea"), Song.title_key("In The Airplane Over The Sea")
  end

  test "artists match on any shared name" do
    assert Song.same_artist?("fun., Janelle Monáe", "Fun")
    assert Song.same_artist?("Mark Ronson, Amy Winehouse", "Amy Winehouse")
    refute Song.same_artist?("Johnny Cash", "Nine Inch Nails")
  end

  test "find_match needs title and artist to agree" do
    assert_equal songs(:amazing_grace), Song.find_match(title: "amazing grace!", artist: "John Newton")
    assert_nil Song.find_match(title: "Amazing Grace", artist: "Someone Else")
  end
end

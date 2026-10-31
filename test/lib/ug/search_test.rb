require "test_helper"

class Ug::SearchTest < ActiveSupport::TestCase
  setup { @results = Ug::Search.parse(file_fixture("ug/search_page.html").read) }

  test "Pro adverts are skipped" do
    assert_equal 3, @results.size
  end

  test "the most-voted free chords version wins" do
    assert_equal "https://tabs.ultimate-guitar.com/tab/traditional/greensleeves-chords-11",
      Ug::Search.best_free_chords(@results, title: "Greensleeves", artist: "Traditional")
  end

  # Seen with "Red Hot Chili Peppers Cant Stop": the search also returns the artist's other songs,
  # and the most-voted was Californication.
  test "only a version of the same song by the same artist counts" do
    results = [
      { title: "Californication", artist: "Red Hot Chili Peppers", type: "Chords", access: "public", rating: 4.9, votes: 9000, url: "https://x/californication" },
      { title: "Can't Stop", artist: "Someone Else", type: "Chords", access: "public", rating: 4.9, votes: 5000, url: "https://x/cover" },
      { title: "Can't Stop", artist: "Red Hot Chili Peppers", type: "Chords", access: "public", rating: 4.7, votes: 800, url: "https://x/cant-stop" }
    ]

    assert_equal "https://x/cant-stop", Ug::Search.best_free_chords(results, title: "Cant Stop", artist: "Red Hot Chili Peppers")
    assert_nil Ug::Search.best_free_chords(results.first(2), title: "Cant Stop", artist: "Red Hot Chili Peppers")
  end

  test "names match without punctuation, with & as and, and with a suffix like (Taylor's Version)" do
    results = [
      { title: "Old Time Rock & Roll", artist: "Bob Seger & The Silver Bullet Band", type: "Chords", access: "public", rating: 4.8, votes: 300, url: "https://x/rock" },
      { title: "I Can See You (Taylor's Version) (From The Vault)", artist: "Taylor Swift", type: "Chords", access: "public", rating: 4.8, votes: 300, url: "https://x/swift" }
    ]

    assert_equal "https://x/rock", Ug::Search.best_free_chords(results, title: "Old Time Rock And Roll", artist: "Bob Seger")
    assert_equal "https://x/swift", Ug::Search.best_free_chords(results, title: "I Can See You", artist: "Taylor Swift")
  end

  test "a shorter title on Ultimate Guitar still matches a longer one in the song list" do
    results = [ { title: "Gimme Gimme Gimme", artist: "ABBA", type: "Chords", access: "public", rating: 4.8, votes: 300, url: "https://x/gimme" } ]

    assert_equal "https://x/gimme", Ug::Search.best_free_chords(results, title: "Gimme! Gimme! Gimme! (A Man After Midnight)", artist: "ABBA")
  end
end

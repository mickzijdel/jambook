require "test_helper"

class Import::SongListTest < ActiveSupport::TestCase
  setup { @result = Import::SongList.new(file_fixture("song_list_excel.csv").open).import }

  test "Excel CSV imports cleanly" do
    assert_equal [ "The Water Is Wide" ], @result.created.map(&:title)
    assert_equal [ songs(:amazing_grace) ], @result.matched
  end

  test "new songs get their tags and the default status" do
    song = Song.find_by!(title: "The Water Is Wide")

    assert_equal %w[ folk slow ], song.tag_names.sort
    assert_predicate song, :maybe?
  end

  test "matched songs gain tags without losing their status" do
    assert_predicate songs(:amazing_grace).reload, :liked?
    assert_equal %w[ hymn slow ], songs(:amazing_grace).tag_names.sort
  end

  test "a Windows-1252 CSV from Excel imports" do
    result = Import::SongList.new(file_fixture("song_list_windows1252.csv").open).import

    assert_equal [ "Beyoncé" ], result.created.map(&:artist)
  end

  test "capitalised headers work and unsaveable rows are skipped" do
    result = Import::SongList.new(file_fixture("song_list_capitalised.csv").open).import

    assert_equal [ "The Skye Boat Song" ], result.created.map(&:title)
    assert_equal 1, result.skipped.size
  end

  test "a file that isn't CSV is refused" do
    assert_raises(Import::Unreadable) { Import::SongList.new(file_fixture("song_list_broken.csv").open).import }
  end

  test "rows without an artist are skipped" do
    assert_equal 1, @result.skipped.size
  end
end

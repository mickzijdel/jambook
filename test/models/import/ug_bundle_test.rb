require "test_helper"

class Import::UgBundleTest < ActiveSupport::TestCase
  test "a new tab becomes a liked song in its written key" do
    import entry(title: "The Water Is Wide", key: "A", capo: 2, content: "G  C\nThe water is wide")
    song = Song.find_by!(title: "The Water Is Wide")

    assert_predicate song, :liked?
    assert_equal [ "G", "A" ], [ song.written_key, song.house_key ]
  end

  test "an existing sheet is never replaced" do
    result = import entry(title: "Amazing Grace", artist: "John Newton", content: "D  G\nla")

    assert_equal "[G]Amazing [C]grace how [G]sweet the sound\nThat [G]saved a [D]wretch like me", songs(:amazing_grace).reload.sheet
    assert_equal 1, result.alternates.size
  end

  test "Chords beats Tab for the same new song" do
    import entry(type: "Tabs", content: "e|--0--|"), entry(type: "Chords", content: "C  F\nla")

    assert_equal "C  F\nla", Song.find_by!(title: "The Water Is Wide").sheet
  end

  test "an advanced tab comes in as maybe" do
    import entry(difficulty: "advanced", content: "C  F\nla")

    assert_predicate Song.find_by!(title: "The Water Is Wide"), :maybe?
  end

  test "a paid tab without a free version is marked for pasting" do
    result = import entry(needs_paste: true, content: nil)

    assert_predicate Song.find_by!(title: "The Water Is Wide"), :needs_paste?
    assert_equal 1, result.needs_paste.size
  end

  test "an entry that can't be saved is skipped and the rest import" do
    result = import entry(title: "!!!", content: "C\nla"), entry(content: "C\nla")

    assert_equal [ "The Water Is Wide" ], result.created.map(&:title)
    assert_equal 1, result.skipped.size
  end

  test "a bundle that isn't JSON is refused" do
    assert_raises(Import::Unreadable) { Import::UgBundle.new(StringIO.new("{not json")).import }
  end

  private
    def entry(**attributes)
      { "url" => "https://tabs.ultimate-guitar.com/tab/traditional/the-water-is-wide-chords-1", "title" => "The Water Is Wide",
        "artist" => "Traditional", "type" => "Chords", "key" => nil, "capo" => 0, "needs_paste" => false }.merge(attributes.transform_keys(&:to_s))
    end

    def import(*entries)
      Import::UgBundle.new(StringIO.new(entries.to_json)).import
    end
end

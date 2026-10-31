require "test_helper"

class Import::UgBundleTest < ActiveSupport::TestCase
  test "a new tab becomes a liked song in its written key" do
    import entry(title: "The Water Is Wide", key: "A", capo: 2, content: "G  C\nThe water is wide")
    song = Song.find_by!(title: "The Water Is Wide")

    assert_predicate song, :liked?
    assert_equal [ "G", "A" ], [ song.written_key, song.house_key ]
  end

  # Ironic's page data has no capo; its sheet opens with "Capo 4th fret".
  test "a capo named at the top of the sheet sets the written key when UG's data has none" do
    import entry(key: "E", content: "Capo 4th fret\n\n[Verse 1]\nD/F#  G\nAn old man")

    assert_equal [ 4, "C", "E" ], Song.find_by!(title: "The Water Is Wide").values_at(:written_capo, :written_key, :house_key)
  end

  test "a capo line is read however it's written" do
    lines = { "Capo: 2" => 2, "(Capo 3rd fret)" => 3, "CAPO ON THE 5TH FRET" => 5, "No capo" => 0 }
    import(*lines.keys.map { entry(title: it, key: "A", content: "#{it}\nC  F\nla") })

    assert_equal lines.values, lines.keys.map { Song.find_by!(title: it).written_capo }
  end

  test "UG's own capo beats one named in the sheet" do
    import entry(key: "F#", capo: 4, content: "Capo on 6\nD  A\nla")

    assert_equal [ 4, "D" ], Song.find_by!(title: "The Water Is Wide").values_at(:written_capo, :written_key)
  end

  # Beatles tabs end with charts of the same chords at other capos ("Capo IV", "Capo 2").
  test "a capo chart lower down in the sheet doesn't count" do
    import entry(key: "E", content: "#{"C  F\nla\n" * 5}Capo 2\nA  D\nla")

    assert_equal [ 0, "E" ], Song.find_by!(title: "The Water Is Wide").values_at(:written_capo, :written_key)
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

  test "a saved tab makes a matching maybe song liked" do
    song = Song.create!(title: "The Water Is Wide", artist: "Traditional", status: "maybe")
    import entry(content: "C  F\nla")

    assert_predicate song.reload, :liked?
  end

  # ug:find bundles hold sheets found for songs already in the list, such as Buck's suggestions.
  test "a sheet found for a song in the list keeps its status" do
    song = Song.create!(title: "The Water Is Wide", artist: "Traditional", status: "maybe")
    import entry(saved: false, content: "C  F\nla")

    assert_equal [ "maybe", "C  F\nla" ], song.reload.values_at(:status, :sheet)
  end

  test "a found sheet with no song to match comes in as maybe" do
    import entry(saved: false, content: "C  F\nla")

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

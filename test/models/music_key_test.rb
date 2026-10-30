require "test_helper"

class MusicKeyTest < ActiveSupport::TestCase
  test "normalize spells enharmonics the house way" do
    assert_equal "Ebm", MusicKey.normalize("D#m")
    assert_equal "F#", MusicKey.normalize("Gb")
    assert_equal "Bb", MusicKey.normalize(" A# ")
  end

  test "normalize rejects what isn't a key" do
    assert_nil MusicKey.normalize("H")
    assert_nil MusicKey.normalize("")
  end

  test "transpose wraps around the octave" do
    assert_equal "Gm", MusicKey.transpose("F#m", 1)
    assert_equal "B", MusicKey.transpose("C", -1)
    assert_equal "C", MusicKey.transpose("B", 1)
    assert_equal "Ebm", MusicKey.transpose("Dm", 1)
  end

  test "transpose refuses an unknown key" do
    assert_raises(ArgumentError) { MusicKey.transpose("H", 1) }
  end

  test "guess takes the first ChordPro chord" do
    assert_equal "Am", MusicKey.guess("{title: X}\nThere [Am]is a [C]house", "chordpro")
  end

  test "guess takes the first chord line of chords-over-lyrics" do
    assert_equal "G", MusicKey.guess("[Verse]\nG    C   G\nAmazing grace", "ultimate_guitar")
    assert_equal "C", MusicKey.guess("Cmaj7  F\nla la", "ultimate_guitar")
  end

  test "guess finds nothing in plain lyrics" do
    assert_nil MusicKey.guess("A day in the life\nno chords here", "ultimate_guitar")
  end
end

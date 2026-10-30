require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  test "a song can't carry the same tag twice" do
    refute_predicate Tagging.new(song: songs(:amazing_grace), tag: tags(:hymn)), :valid?
  end
end

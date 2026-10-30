require "test_helper"

class Ug::SavedTabsTest < ActiveSupport::TestCase
  setup { @urls = Ug::SavedTabs.new(file_fixture("ug/saved_tabs.json").read).urls }

  test "bass parts and riff tabs are left out" do
    assert_equal %w[ amazing-grace-chords-1 greensleeves-official-3 ], @urls.map { it.split("/").last }
  end

  test "a chord sheet beats a tab of the same song" do
    refute_includes @urls, "https://tabs.ultimate-guitar.com/tab/john-newton/amazing-grace-tabs-2"
  end
end

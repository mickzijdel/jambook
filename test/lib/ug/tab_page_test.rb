require "test_helper"

class Ug::TabPageTest < ActiveSupport::TestCase
  setup { @tab = Ug::TabPage.parse(file_fixture("ug/tab_page.html").read) }

  test "a tab page yields its song, key and capo" do
    assert_equal [ "Amazing Grace", "John Newton", "A", 2 ], @tab.values_at(:title, :artist, :key, :capo)
  end

  test "a tab without metadata has no capo" do
    data = { store: { page: { data: { tab: { song_name: "X" }, tab_view: { meta: [] } } } } }
    html = %(<div class="js-store" data-content="#{ERB::Util.html_escape(data.to_json)}"></div>)

    assert_equal 0, Ug::TabPage.parse(html)[:capo]
  end

  test "tab markup is stripped" do
    assert_includes @tab[:content], "G        C"
    refute_includes @tab[:content], "[ch]"
  end
end

require "test_helper"

class Ug::SearchTest < ActiveSupport::TestCase
  setup { @results = Ug::Search.parse(file_fixture("ug/search_page.html").read) }

  test "Pro adverts are skipped" do
    assert_equal 3, @results.size
  end

  test "the most-voted free chords version wins" do
    assert_equal "https://tabs.ultimate-guitar.com/tab/traditional/greensleeves-chords-11", Ug::Search.best_free_chords(@results)
  end
end

require "test_helper"

class Ug::FetcherTest < ActiveSupport::TestCase
  TAB = "https://tabs.ultimate-guitar.com/tab/john-newton/amazing-grace-chords-1"
  OFFICIAL = "https://tabs.ultimate-guitar.com/tab/traditional/greensleeves-official-3"
  FREE = "https://tabs.ultimate-guitar.com/tab/traditional/greensleeves-chords-11"
  SEARCH = %r{\Ahttps://www\.ultimate-guitar\.com/search\.php}

  setup do
    @dir = Dir.mktmpdir("ug-fetcher")
    @urls = File.join(@dir, "urls.txt")
    @bundle = File.join(@dir, "bundle.json")
    stub_request(:get, TAB).to_return(body: file_fixture("ug/tab_page.html").read)
    stub_request(:get, FREE).to_return(body: file_fixture("ug/tab_page.html").read)
    stub_request(:get, SEARCH).to_return(body: file_fixture("ug/search_page.html").read)
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "an official tab is swapped for the best free chords" do
    fetch(OFFICIAL)

    assert_not_requested :get, OFFICIAL
    assert_requested :get, FREE
    assert_equal [ FREE, OFFICIAL ], bundle.first.values_at("url", "official_url")
  end

  test "an official tab with no free version needs a paste" do
    stub_request(:get, SEARCH).to_return(body: "<html></html>")
    fetch(OFFICIAL)

    assert bundle.first["needs_paste"]
    assert_equal "Greensleeves", bundle.first["title"]
  end

  test "a second run resumes without refetching" do
    fetch(TAB)
    WebMock.reset_executed_requests!
    fetch(TAB)

    assert_not_requested :get, TAB
    assert_equal 1, bundle.size
  end

  test "a failed page is recorded and the run carries on" do
    stub_request(:get, TAB).to_return(status: 403)
    fetch(TAB)

    assert_equal "HTTP 403", bundle.first["error"]
  end

  private
    def fetch(*urls)
      File.write(@urls, "# saved tabs\n" + urls.join("\n") + "\n")
      Ug::Fetcher.new(urls_path: @urls, bundle_path: @bundle, delay: 0, log: StringIO.new).fetch
    end

    def bundle
      JSON.parse(File.read(@bundle))
    end
end

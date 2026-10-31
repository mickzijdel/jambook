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

  test "an official tab whose search only finds other songs needs a paste" do
    fetch("https://tabs.ultimate-guitar.com/tab/traditional/scarborough-fair-official-4")

    assert_not_requested :get, FREE
    assert bundle.first["needs_paste"]
    assert_equal "Scarborough Fair", bundle.first["title"]
  end

  test "a second run resumes without refetching" do
    fetch(TAB)
    WebMock.reset_executed_requests!
    fetch(TAB)

    assert_not_requested :get, TAB
    assert_equal 1, bundle.size
  end

  test "an unreadable page is recorded and the run carries on" do
    stub_request(:get, TAB).to_return(body: %(<div class="js-store" data-content="{not json"></div>))
    fetch(TAB, FREE)

    assert_match(/unreadable/, bundle.first["error"])
    assert_equal FREE, bundle.last["url"]
  end

  test "a failed page is recorded and the run carries on" do
    stub_request(:get, TAB).to_return(status: 403)
    fetch(TAB)

    assert_equal "HTTP 403", bundle.first["error"]
  end

  test "a song without a sheet gets the best free chords, under its own name so the import matches it" do
    find_sheets([ { "title" => "Greensleeves (Traditional English Ballad)", "artist" => "Traditional" } ])

    assert_requested :get, FREE
    assert_equal [ FREE, "Greensleeves (Traditional English Ballad)", "Traditional" ], bundle.first.values_at("url", "title", "artist")
  end

  test "a song with no free version is listed as needing a paste" do
    stub_request(:get, SEARCH).to_return(body: "<html></html>")
    find_sheets([ { "title" => "Greensleeves", "artist" => "Traditional" } ])

    assert bundle.first["needs_paste"]
  end

  test "finding sheets resumes without searching again" do
    songs = [ { "title" => "Greensleeves", "artist" => "Traditional" } ]
    find_sheets(songs)
    WebMock.reset_executed_requests!
    find_sheets(songs)

    assert_not_requested :get, SEARCH
    assert_equal 1, bundle.size
  end

  private
    def find_sheets(songs)
      Ug::Fetcher.new(urls_path: @urls, bundle_path: @bundle, delay: 0, log: StringIO.new).find(songs)
    end

    def fetch(*urls)
      File.write(@urls, "# saved tabs\n" + urls.join("\n") + "\n")
      Ug::Fetcher.new(urls_path: @urls, bundle_path: @bundle, delay: 0, log: StringIO.new).fetch
    end

    def bundle
      JSON.parse(File.read(@bundle))
    end
end

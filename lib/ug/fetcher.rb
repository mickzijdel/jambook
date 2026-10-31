require "net/http"

# Downloads public tab pages into a bundle file for Import::UgBundle. Run it on your own computer:
# Ultimate Guitar often blocks server addresses. Paid (official/Pro) tabs are never requested;
# the most-voted free chords version of the same song stands in for them.
class Ug::Fetcher
  USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"
  PAID = /-(official|pro)-\d+\z/

  def initialize(urls_path:, bundle_path:, delay: 1, log: $stdout)
    @urls_path, @bundle_path, @delay, @log = urls_path, bundle_path, delay, log
  end

  def fetch
    urls.each { add(entry_for(it), it) unless done?(it) }
  end

  # For songs with no sheet yet ({ "title", "artist" } each): the best free chords version, kept under
  # the song's own title and artist so the import fills that song instead of adding another, and
  # marked as not one of the host's saved tabs so the import leaves the song's status alone.
  def find(songs)
    songs.each do |song|
      title, artist = song.values_at("title", "artist")
      add(search(title, artist).merge("title" => title, "artist" => artist, "saved" => false), "#{artist} - #{title}") unless entries.any? { it["title"] == title && it["artist"] == artist }
    end
  end

  private
    def urls
      File.readlines(@urls_path, chomp: true).map(&:strip).reject { it.empty? || it.start_with?("#") }
    end

    def add(entry, label)
      entries << entry
      File.write(@bundle_path, JSON.pretty_generate(entries))
      @log.puts "#{entries.size}: #{label}"
    end

    def entries
      @entries ||= File.exist?(@bundle_path) ? JSON.parse(File.read(@bundle_path)) : []
    end

    def done?(url)
      entries.any? { it["url"] == url || it["official_url"] == url }
    end

    def entry_for(url)
      url.match?(PAID) ? free_stand_in(url) : tab_entry(url)
    end

    def tab_entry(url, official_url: nil)
      response = get(url)

      if response.is_a?(Net::HTTPSuccess)
        { "url" => url, "official_url" => official_url, "needs_paste" => false, **Ug::TabPage.parse(response.body).transform_keys(&:to_s) }
      else
        { "url" => url, "official_url" => official_url, "error" => "HTTP #{response.code}" }
      end
    rescue JSON::ParserError, TypeError, NoMethodError => error
      # One odd page shouldn't stop a run of a hundred; it stays in the bundle as an error.
      { "url" => url, "official_url" => official_url, "error" => "unreadable page: #{error.class}" }
    end

    def free_stand_in(official_url)
      artist, title = names_from(official_url)
      search(title, artist, official_url:)
    end

    # A long subtitle in brackets makes the search find nothing, so it's left out of the query, and so
    # can a catch-all artist ("Misc Musicals"), so the title alone is tried next.
    def search(title, artist, official_url: nil)
      short = title.sub(/\s*\(.*\)\s*\z/, "")
      free_url = [ "#{artist} #{short}", short ].lazy.filter_map { |query| best_free_chords(query, title:, artist:) }.first

      if free_url
        tab_entry(free_url, official_url: official_url)
      else
        { "url" => official_url, "official_url" => official_url, "title" => title, "artist" => artist, "needs_paste" => true }
      end
    end

    def best_free_chords(query, title:, artist:)
      response = get(Ug::Search.url_for(query))
      Ug::Search.best_free_chords(Ug::Search.parse(response.body), title:, artist:) if response.is_a?(Net::HTTPSuccess)
    end

    # /tab/red-hot-chili-peppers/cant-stop-official-1918879 → ["Red Hot Chili Peppers", "Cant Stop"]
    def names_from(url)
      artist, song = URI(url).path.delete_prefix("/tab/").split("/")
      [ artist, song.sub(PAID, "") ].map { it.tr("-", " ").titleize }
    end

    def get(url)
      Net::HTTP.get_response(URI(url), { "User-Agent" => USER_AGENT }).tap { sleep @delay }
    end
end

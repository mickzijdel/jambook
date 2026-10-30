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
    urls.each do |url|
      unless done?(url)
        entries << entry_for(url)
        File.write(@bundle_path, JSON.pretty_generate(entries))
        @log.puts "#{entries.size}: #{url}"
      end
    end
  end

  private
    def urls
      File.readlines(@urls_path, chomp: true).map(&:strip).reject { it.empty? || it.start_with?("#") }
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
      response = get(Ug::Search.url_for("#{artist} #{title}"))
      free_url = Ug::Search.best_free_chords(Ug::Search.parse(response.body)) if response.is_a?(Net::HTTPSuccess)

      if free_url
        tab_entry(free_url, official_url: official_url)
      else
        { "url" => official_url, "official_url" => official_url, "title" => title, "artist" => artist, "needs_paste" => true }
      end
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

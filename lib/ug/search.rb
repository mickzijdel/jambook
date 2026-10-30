module Ug::Search
  URL = "https://www.ultimate-guitar.com/search.php"

  def self.url_for(query)
    "#{URL}?#{URI.encode_www_form(search_type: "title", value: query)}"
  end

  # Results without a type are Pro adverts.
  def self.parse(html)
    Array(Ug.page_data(html)["results"]).filter_map do |result|
      if result["type"]
        { title: result["song_name"], artist: result["artist_name"], type: result["type"], access: result["tab_access_type"],
          rating: result["rating"].to_f, votes: result["votes"].to_i, url: result["tab_url"] }
      end
    end
  end

  def self.best_free_chords(results)
    results.select { it[:type] == "Chords" && it[:access] == "public" }.max_by { [ it[:votes], it[:rating] ] }&.dig(:url)
  end
end

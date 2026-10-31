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

  # The search also returns the artist's other songs and covers, so only the same song by the same
  # artist counts, compared the way imports match songs. One title may run on past the other:
  # "I Can See You (Taylor's Version)", "Gimme! Gimme! Gimme! (A Man After Midnight)".
  def self.best_free_chords(results, title:, artist:)
    results.select { it[:type] == "Chords" && it[:access] == "public" && same_song?(it, title:, artist:) }
      .max_by { [ it[:votes], it[:rating] ] }&.dig(:url)
  end

  def self.same_song?(result, title:, artist:)
    found, wanted = Song.title_key(result[:title]), Song.title_key(title)
    found.present? && wanted.present? && (found.start_with?(wanted) || wanted.start_with?(found)) && Song.same_artist?(result[:artist], artist)
  end
  private_class_method :same_song?
end

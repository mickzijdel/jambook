# Matches imported rows to existing songs despite spelling differences in titles and artists.
module Song::Matchable
  extend ActiveSupport::Concern

  NUMBER_WORDS = %w[ zero one two three four five six seven eight nine ten ].each_with_index.to_h.freeze
  ARTIST_SEPARATORS = /,|&|\band\b|\bfeat\.?|\bft\.?|\bwith\b/i

  included do
    before_validation { self.title_key = self.class.title_key(title) }

    validates :title_key, presence: true
  end

  class_methods do
    def title_key(title)
      words = I18n.transliterate(title.to_s).downcase
        .gsub("&", " and ").gsub("aeroplane", "airplane").gsub(/\bpt\./, "part")
        .split(/[^a-z0-9]+/).reject(&:empty?)
      words = words.map { |word| NUMBER_WORDS.fetch(word, word).to_s }
      words.shift if words.first == "the"
      words.join
    end

    def artist_keys(artist)
      artist.to_s.split(ARTIST_SEPARATORS).map { |name| title_key(name) }.reject(&:empty?).to_set
    end

    def same_artist?(one, other)
      artist_keys(one).intersect?(artist_keys(other))
    end

    def find_match(title:, artist:)
      where(title_key: title_key(title)).find { |song| same_artist?(song.artist, artist) }
    end
  end
end

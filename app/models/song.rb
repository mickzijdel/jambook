class Song < ApplicationRecord
  include Broadcastable, Keys, Matchable, Taggable

  enum :status, %w[ liked maybe ].index_by(&:itself), validate: true
  enum :sheet_format, %w[ chordpro ultimate_guitar ].index_by(&:itself), validate: true

  validates :title, :artist, presence: true
  # Only web links: a javascript: URL here would run script for every guest.
  validates :listen_url, :ug_url, format: { with: %r{\Ahttps?://\S+\z}i }, allow_blank: true

  scope :preloaded, -> { preload(:tags) }
  scope :matching, ->(query) { where("title LIKE :query OR artist LIKE :query", query: "%#{sanitize_sql_like(query)}%") }

  def self.filtered(query: nil, status: nil, tag: nil)
    songs = all
    songs = songs.matching(query) if query.present?
    songs = songs.where(status: status) if statuses.key?(status)
    songs = songs.tagged(tag) if tag.present?
    songs
  end

  def playable?
    sheet.present? && written_key.present?
  end
end

class Song < ApplicationRecord
  include Keys, Matchable, Taggable

  enum :status, %w[ liked maybe ].index_by(&:itself), validate: true
  enum :sheet_format, %w[ chordpro ultimate_guitar ].index_by(&:itself), validate: true

  validates :title, :artist, presence: true

  def playable?
    sheet.present? && written_key.present?
  end
end

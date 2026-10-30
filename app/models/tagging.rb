class Tagging < ApplicationRecord
  belongs_to :song
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :song_id }
end

class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :songs, through: :taggings

  validates :name, presence: true, uniqueness: true
end

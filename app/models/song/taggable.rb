module Song::Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, dependent: :destroy
    has_many :tags, through: :taggings

    scope :tagged, ->(name) { joins(:tags).where(tags: { name: name }) }
  end

  def tag_names
    tags.map(&:name)
  end

  def tag_names=(names)
    names = names.split(",") if names.is_a?(String)
    self.tags = names.map(&:strip).compact_blank.uniq.map { |name| Tag.find_or_create_by!(name: name) }
  end
end

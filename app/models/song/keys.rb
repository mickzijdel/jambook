module Song::Keys
  extend ActiveSupport::Concern

  included do
    normalizes :written_key, :house_key, with: ->(key) { MusicKey.normalize(key) }

    before_validation :guess_written_key, :derive_house_key

    validates :written_capo, inclusion: { in: 0..11 }
    validates :written_key, :house_key, inclusion: { in: MusicKey::KEYS }, allow_nil: true
  end

  private
    def guess_written_key
      if written_key.blank? && sheet.present?
        self.written_key = MusicKey.guess(sheet, sheet_format)
        self.key_guessed = written_key.present?
      end
    end

    # The house key is the sounding key: the written key moved up by the written capo.
    def derive_house_key
      if house_key.blank? && written_key.present?
        self.house_key = MusicKey.transpose(written_key, written_capo.to_i)
      end
    end
end

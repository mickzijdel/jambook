# Imports a bundle from Ug::Fetcher. Fills in, never overwrites: a song that already has a sheet
# keeps it and the tab is listed as an alternate. Chords versions are imported before other types.
class Import::UgBundle
  def initialize(io)
    @entries = JSON.parse(io.read)
  end

  def import
    Import::Result.empty.tap do |result|
      chords, others = @entries.reject { it["error"] }.partition { it["type"] == "Chords" }
      (chords + others).each { import_entry(it, result) }
    end
  end

  private
    def import_entry(entry, result)
      if (song = Song.find_match(title: entry["title"], artist: entry["artist"]))
        song.liked! if status_for(entry) == "liked"
        fill(song, entry, result)
        result.matched << song
      else
        song = Song.new(title: entry["title"], artist: entry["artist"], status: status_for(entry))
        fill(song, entry, result)
        result.created << song
      end
    end

    # "Can play it now": an advanced tab comes in as a maybe.
    def status_for(entry)
      entry["difficulty"] == "advanced" ? "maybe" : "liked"
    end

    def fill(song, entry, result)
      song.ug_url = entry["official_url"] || entry["url"] if song.ug_url.blank?
      song.ug_type = entry["official_url"] ? "Official" : entry["type"] if song.ug_type.blank?

      if entry["needs_paste"]
        song.needs_paste = song.sheet.blank?
        result.needs_paste << song
      elsif song.sheet.blank? && entry["content"].present?
        add_sheet(song, entry)
      elsif entry["content"].present?
        result.alternates << entry
      end

      song.save!
    end

    def add_sheet(song, entry)
      sounding_key = MusicKey.normalize(entry["key"])
      capo = entry["capo"].to_i

      song.assign_attributes(sheet: entry["content"], sheet_format: "ultimate_guitar", written_capo: capo, needs_paste: false,
        written_key: (MusicKey.transpose(sounding_key, -capo) if sounding_key), house_key: sounding_key)
    end
end

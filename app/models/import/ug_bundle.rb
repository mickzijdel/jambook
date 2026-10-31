# Imports a bundle from Ug::Fetcher. Fills in, never overwrites: a song that already has a sheet
# keeps it and the tab is listed as an alternate. Chords versions are imported before other types.
class Import::UgBundle
  # "Capo 4th fret" near the top, for a tab whose page data has no capo. Further down, sheets chart
  # the same chords at other capos. The sheet editor reads a paste the same way (chord_sheet_helpers).
  CAPO_LINE = /^[^\w\n]*capo(?![a-z])[^\w\n]*(?:(?:on|at|the)\s+)*(\d{1,2})(?!\d)/i

  def initialize(io)
    @entries = JSON.parse(io.read)
  rescue JSON::ParserError => error
    raise Import::Unreadable, "it isn't a bundle from ug:fetch (#{error.message})"
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
    rescue ActiveRecord::RecordInvalid
      result.skipped << entry["title"]
    end

    # "Can play it now": an advanced tab comes in as a maybe. A sheet that ug:find found for a song in
    # the list ("saved": false) isn't one of the host's saved tabs, so it doesn't make the song liked.
    def status_for(entry)
      entry["saved"] == false || entry["difficulty"] == "advanced" ? "maybe" : "liked"
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
      capo = entry["capo"].to_i.nonzero? || capo_line(entry["content"])

      song.assign_attributes(sheet: entry["content"], sheet_format: "ultimate_guitar", written_capo: capo, needs_paste: false,
        written_key: (MusicKey.transpose(sounding_key, -capo) if sounding_key), house_key: sounding_key)
    end

    def capo_line(sheet)
      capo = sheet.lines.first(10).join[CAPO_LINE, 1].to_i
      capo.between?(1, 11) ? capo : 0
    end
end

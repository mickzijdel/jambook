require "csv"

# Imports a CSV song list (header: title,artist,status,tags; tags separated by ";").
# Fills in, never overwrites: a matched song only gains tags and can only go from maybe to liked.
class Import::SongList
  def initialize(io)
    @io = io
  end

  def import
    Import::Result.empty.tap do |result|
      rows.each.with_index(2) do |row, line|
        import_row(row, line, result)
      end
    end
  end

  private
    def rows
      CSV.parse(utf8_text.delete_prefix("\uFEFF"), headers: true, strip: true, skip_blanks: true,
        header_converters: ->(header) { header.to_s.strip.downcase })
    rescue CSV::MalformedCSVError => error
      raise Import::Unreadable, "it isn't valid CSV (#{error.message})"
    end

    # Excel's "CSV (Comma delimited)" on Windows saves Windows-1252, not UTF-8.
    def utf8_text
      text = @io.read.force_encoding(Encoding::UTF_8)
      text.valid_encoding? ? text : text.force_encoding(Encoding::Windows_1252).encode(Encoding::UTF_8)
    end

    def import_row(row, line, result)
      title, artist = row["title"], row["artist"]
      status = Song.statuses.key?(row["status"].to_s.downcase) ? row["status"].downcase : "maybe"
      tags = row["tags"].to_s.split(";").map(&:strip).compact_blank

      if title.blank? || artist.blank?
        result.skipped << line
      elsif (song = Song.find_match(title: title, artist: artist))
        song.update!(tag_names: song.tag_names | tags, status: song.liked? ? "liked" : status)
        result.matched << song
      else
        result.created << Song.create!(title: title, artist: artist, status: status, tag_names: tags)
      end
    rescue ActiveRecord::RecordInvalid
      result.skipped << line
    end
end

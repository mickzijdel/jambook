# Picks the tabs worth importing from the saved-tabs snippet's JSON: chord sheets only
# (no bass parts, riffs or Guitar Pro files), the first one saved per song.
class Ug::SavedTabs
  KIND = /-(chords|official|ukulele|tabs|bass|guitar-pro|drums|power|video)-\d+\z/
  CHORD_SHEETS = %w[ chords official ukulele ].freeze

  def initialize(json)
    @tabs = JSON.parse(json).fetch("tabs")
  end

  def urls
    @tabs.map { it["tab_url"] }.select { CHORD_SHEETS.include?(it[KIND, 1]) }.uniq { it.sub(KIND, "") }
  end
end

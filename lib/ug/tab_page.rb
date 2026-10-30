module Ug::TabPage
  MARKUP = %r{\[/?(ch|tab)\]}

  # tonality_name is the key the tab sounds in; capo is the capo it is written for.
  def self.parse(html)
    data = Ug.page_data(html)
    tab, view = data.fetch("tab", {}), data.fetch("tab_view", {})

    { title: tab["song_name"], artist: tab["artist_name"], type: tab["type"], difficulty: tab["difficulty"],
      key: tab["tonality_name"].presence, capo: view.dig("meta", "capo").to_i,
      content: view.dig("wiki_tab", "content")&.gsub(MARKUP, "") }
  end
end

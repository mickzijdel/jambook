# Ultimate Guitar import, for a host's own saved tabs (personal use). Run on your own computer.
namespace :ug do
  desc 'Pick chord sheets from the saved-tabs snippet output: bin/rails "ug:urls[ug-saved-tabs.json,urls.txt]"'
  task :urls, %i[ snippet_json urls_txt ] => :environment do |_task, args|
    urls = Ug::SavedTabs.new(File.read(args[:snippet_json])).urls
    File.write(args[:urls_txt], urls.join("\n") + "\n")
    puts "Wrote #{urls.size} chord sheets to #{args[:urls_txt]}."
  end

  desc 'Download public tabs into a bundle to upload: bin/rails "ug:fetch[urls.txt,bundle.json]"'
  task :fetch, %i[ urls_txt bundle_json ] => :environment do |_task, args|
    Ug::Fetcher.new(urls_path: args[:urls_txt], bundle_path: args[:bundle_json]).fetch
  end

  desc 'Find free chords for songs with no sheet (a CSV with title and artist columns): bin/rails "ug:find[songs.csv,bundle.json]"'
  task :find, %i[ songs_csv bundle_json ] => :environment do |_task, args|
    songs = CSV.read(args[:songs_csv], headers: true).map(&:to_h)
    Ug::Fetcher.new(urls_path: nil, bundle_path: args[:bundle_json]).find(songs)
  end
end

# What an import did: songs created or matched, skipped row numbers, songs that need a pasted
# sheet, and tabs that lost to a sheet the song already had.
Import::Result = Data.define(:created, :matched, :skipped, :needs_paste, :alternates) do
  def self.empty
    new(created: [], matched: [], skipped: [], needs_paste: [], alternates: [])
  end
end

class Songs::NotesController < ApplicationController
  include SongScoped

  # GET /songs/:song_id/notes/edit
  def edit
  end

  # PATCH /songs/:song_id/notes
  def update
    @song.update!(notes: params.expect(song: [ :notes ])[:notes])
    render partial: "songs/notes", locals: { song: @song }
  end
end

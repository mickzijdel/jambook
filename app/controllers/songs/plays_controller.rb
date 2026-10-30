class Songs::PlaysController < ApplicationController
  include SongScoped

  # POST /songs/:song_id/play
  def create
    Room.instance.play(@song)
    redirect_to root_path
  end
end

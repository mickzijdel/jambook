class SongsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  # GET /songs
  def index
    @playing_song_id = Room.instance.current_song_id
    @songs = Song.preloaded.filtered(query: params[:q], status: params[:status], tag: params[:tag]).order(:artist, :title)
  end

  # GET /songs/:id
  def show
    @song = Song.find(params[:id])
  end
end

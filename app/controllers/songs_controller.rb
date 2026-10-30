class SongsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_song, only: %i[ show edit update destroy ]

  # GET /songs
  def index
    @playing_song_id = Room.instance.current_song_id
    @songs = Song.preloaded.filtered(query: params[:q], status: params[:status], tag: params[:tag]).order(:artist, :title)
  end

  # GET /songs/:id
  def show
  end

  # GET /songs/new
  def new
    @song = Song.new
  end

  # POST /songs
  def create
    @song = Song.new(song_params)

    if @song.save
      redirect_to @song
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /songs/:id/edit
  def edit
  end

  # PATCH /songs/:id
  def update
    # Saving the form with a key confirms it, guessed or not.
    @song.key_guessed = false if song_params[:written_key].present?

    if @song.update(song_params)
      redirect_to @song
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /songs/:id
  def destroy
    @song.destroy!
    redirect_to songs_path
  end

  private
    def set_song
      @song = Song.find(params[:id])
    end

    def song_params
      params.expect(song: %i[ title artist status tag_names ug_url ug_type listen_url written_key written_capo house_key notes sheet sheet_format ])
    end
end

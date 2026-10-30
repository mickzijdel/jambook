class Imports::SongListsController < ApplicationController
  # GET /imports/song_list/new
  def new
  end

  # POST /imports/song_list
  def create
    @result = Import::SongList.new(params.expect(:file)).import
    render :create
  rescue Import::Unreadable => error
    flash.now[:alert] = "Jambook couldn't read that file: #{error.message}."
    render :new, status: :unprocessable_entity
  end
end

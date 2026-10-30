class RoomsController < ApplicationController
  allow_unauthenticated_access only: :show

  # GET /
  def show
    @room = Room.instance
    @song = @room.current_song
  end
end

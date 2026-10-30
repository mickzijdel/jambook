class RoomsController < ApplicationController
  allow_unauthenticated_access only: :show

  # GET /
  def show
  end
end

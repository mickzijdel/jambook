class Rooms::KeysController < ApplicationController
  STEPS = [ -1, 1 ].freeze

  # PATCH /room/key
  def update
    delta = params[:delta].to_i

    if STEPS.include?(delta) && Room.instance.room_key.present?
      Room.instance.transpose(delta)
      redirect_to root_path
    else
      head :unprocessable_entity
    end
  end
end

class GuestAccessesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_guest_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_guest_access_path, alert: "Try again later." }

  # GET /guest_access/new
  def new
  end

  # POST /guest_access
  def create
    if Setting.instance.authenticate_guest_password(params[:password].to_s)
      grant_guest_access
      redirect_to after_guest_access_url
    else
      flash.now[:alert] = "That's not the password."
      render :new, status: :unprocessable_entity
    end
  end
end

class GuestAccessesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_guest_access
  WRONG_GUESSES_ALLOWED = 10

  # Counts wrong guesses only: every guest at a jam shares one Wi-Fi address.
  before_action :refuse_after_wrong_guesses, only: :create

  # GET /guest_access/new
  def new
  end

  # POST /guest_access
  def create
    if Setting.instance.authenticate_guest_password(params[:password].to_s)
      grant_guest_access
      redirect_to after_guest_access_url
    else
      Rails.cache.increment(wrong_guesses_key, 1, expires_in: 3.minutes)
      flash.now[:alert] = "That's not the password."
      render :new, status: :unprocessable_entity
    end
  end

  private
    def refuse_after_wrong_guesses
      if Rails.cache.read(wrong_guesses_key).to_i >= WRONG_GUESSES_ALLOWED
        redirect_to new_guest_access_path, alert: "Try again later."
      end
    end

    def wrong_guesses_key
      "guest-access/wrong-guesses/#{request.remote_ip}"
    end
end

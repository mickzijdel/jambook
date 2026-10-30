class SettingsController < ApplicationController
  before_action :set_setting

  # GET /settings/edit
  def edit
  end

  # PATCH /settings
  def update
    if @setting.update(setting_params)
      redirect_to edit_settings_path, notice: "Guest password changed. Guests need the new one."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_setting
      @setting = Setting.instance
    end

    def setting_params
      params.expect(setting: %i[ guest_password guest_password_confirmation ])
    end
end

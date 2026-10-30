class Imports::UgBundlesController < ApplicationController
  # GET /imports/ug_bundle/new
  def new
  end

  # POST /imports/ug_bundle
  def create
    @result = Import::UgBundle.new(params.expect(:file)).import
    render :create
  rescue Import::Unreadable => error
    flash.now[:alert] = "Jambook couldn't read that file: #{error.message}."
    render :new, status: :unprocessable_entity
  end
end

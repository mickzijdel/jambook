module SongScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_song
  end

  private
    def set_song
      @song = Song.find(params[:song_id])
    end
end

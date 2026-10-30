# Guests get in with the shared password; the host's session counts as guest access too.
module GuestAccess
  extend ActiveSupport::Concern

  included do
    before_action :require_guest_access
    helper_method :guest_access?
  end

  private
    def guest_access?
      authenticated? || cookies.signed[:guest_access] == Setting.instance.guest_access_version
    end

    def require_guest_access
      unless guest_access?
        session[:return_to_after_guest_access] = request.url
        redirect_to new_guest_access_path
      end
    end

    def grant_guest_access
      cookies.signed[:guest_access] = { value: Setting.instance.guest_access_version, expires: 30.days, httponly: true, same_site: :lax }
    end

    def after_guest_access_url
      session.delete(:return_to_after_guest_access) || root_url
    end
end

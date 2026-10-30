# The one row of instance-wide settings: today, the shared guest password.
class Setting < ApplicationRecord
  has_secure_password :guest_password, validations: false

  before_update :lock_out_old_guests, if: :guest_password_digest_changed?

  def self.instance
    first_or_create!
  end

  private
    # Guest cookies carry the version they were granted under, so bumping it signs every guest out.
    def lock_out_old_guests
      self.guest_access_version += 1
    end
end

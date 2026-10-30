class ApplicationController < ActionController::Base
  include Authentication, GuestAccess
  # Import maps need Safari 16.4, Chrome 89, Firefox 108; :modern would turn away iPhones stuck on iOS 16.
  allow_browser versions: { safari: 16.4, chrome: 89, firefox: 108, opera: 75, ie: false }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end

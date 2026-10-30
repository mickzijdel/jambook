require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # SYSTEM_TESTS_BROWSER=chrome shows the browser while the tests run.
  driven_by :selenium, using: ENV.fetch("SYSTEM_TESTS_BROWSER", "headless_chrome").to_sym, screen_size: [ 390, 844 ]
end

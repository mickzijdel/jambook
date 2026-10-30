require "test_helper"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # SYSTEM_TESTS_BROWSER=chrome shows the browser while the tests run.
  # The capo stepper's value, and the shapes line beside it.
  def assert_capo(capo, shapes: nil)
    assert_selector "[data-chord-sheet-target=capo]", text: capo.to_s
    assert_text "you play #{shapes} shapes" if shapes
  end

  driven_by :selenium, using: ENV.fetch("SYSTEM_TESTS_BROWSER", "headless_chrome").to_sym, screen_size: [ 390, 844 ]
end

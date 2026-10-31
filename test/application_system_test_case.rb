require "test_helper"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # shortcut: browser tests run one at a time. With parallel workers some clicks, typing and live
  # updates get lost (locally and on CI; cause not found, see plans/off-topic-improvements.md).
  # Run them in parallel again once that is fixed. PARALLEL_WORKERS still overrides this.
  parallelize(workers: 1)

  # SYSTEM_TESTS_BROWSER=chrome shows the browser while the tests run.
  driven_by :selenium, using: ENV.fetch("SYSTEM_TESTS_BROWSER", "headless_chrome").to_sym, screen_size: [ 390, 844 ]

  # The capo stepper's value, and the shapes line beside it.
  def assert_capo(capo, shapes: nil)
    assert_selector "[data-chord-sheet-target=capo]", text: capo.to_s
    assert_text "you play #{shapes} shapes" if shapes
  end
end

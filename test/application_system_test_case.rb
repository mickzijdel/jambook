require "test_helper"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # SYSTEM_TESTS_BROWSER=chrome shows the browser while the tests run.
  driven_by :selenium, using: ENV.fetch("SYSTEM_TESTS_BROWSER", "headless_chrome").to_sym, screen_size: [ 390, 844 ]

  # A page's controllers connect a moment after it loads, and typing into a field before its controller
  # has connected changes nothing (seen on CI as a pasted sheet that filled in no key).
  def visit(...)
    super.tap { wait_for_controllers }
  end

  def wait_for_controllers
    page.document.synchronize do
      raise Capybara::ExpectationNotMet, "Stimulus controllers not connected yet" unless evaluate_script(<<~JS)
        window.Stimulus !== undefined && [ ...document.querySelectorAll("[data-controller]") ].every((element) =>
          element.dataset.controller.split(/\s+/).filter(Boolean).every((name) => window.Stimulus.getControllerForElementAndIdentifier(element, name)))
      JS
    end
  end

  # The capo stepper's value, and the shapes line beside it.
  def assert_capo(capo, shapes: nil)
    assert_selector "[data-chord-sheet-target=capo]", text: capo.to_s
    assert_text "you play #{shapes} shapes" if shapes
  end
end

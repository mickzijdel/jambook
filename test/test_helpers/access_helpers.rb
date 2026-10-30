# The same two helpers in integration and system tests: sign in as the host, or get in as a guest.
module AccessHelpers
  GUEST_PASSWORD = "jam-session"

  module Integration
    def sign_in_as_host
      sign_in_as(users(:one))
    end

    def enter_guest_password(password = GUEST_PASSWORD)
      post guest_access_path, params: { password: password }
    end
  end

  module System
    def sign_in_as_host
      visit new_session_path
      fill_in "email_address", with: users(:one).email_address
      fill_in "password", with: "password"
      click_on "Sign in"

      assert_no_current_path new_session_path
    end

    def enter_guest_password(password = GUEST_PASSWORD)
      visit new_guest_access_path
      fill_in "Password", with: password
      click_on "Let me in"

      assert_no_current_path new_guest_access_path
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) { include AccessHelpers::Integration }
ActiveSupport.on_load(:action_dispatch_system_test_case) { include AccessHelpers::System }

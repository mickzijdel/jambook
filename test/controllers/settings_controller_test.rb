require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "the host sets a new guest password" do
    sign_in_as_host

    assert_difference -> { Setting.instance.guest_access_version }, 1 do
      patch settings_path, params: { setting: { guest_password: "new-one", guest_password_confirmation: "new-one" } }
    end
    assert Setting.instance.authenticate_guest_password("new-one")
  end

  test "a mismatched confirmation changes nothing" do
    sign_in_as_host

    assert_no_difference -> { Setting.instance.guest_access_version } do
      patch settings_path, params: { setting: { guest_password: "new-one", guest_password_confirmation: "other" } }
    end
    assert_response :unprocessable_entity
  end

  test "a blank guest password is refused" do
    sign_in_as_host
    patch settings_path, params: { setting: { guest_password: "", guest_password_confirmation: "" } }

    assert_response :unprocessable_entity
  end

  test "guests can't change settings" do
    enter_guest_password
    get edit_settings_path

    assert_redirected_to new_session_path
  end
end

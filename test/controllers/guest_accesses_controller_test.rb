require "test_helper"

class GuestAccessesControllerTest < ActionDispatch::IntegrationTest
  test "guests need the password" do
    get root_path

    assert_redirected_to new_guest_access_path
  end

  test "a wrong password is refused" do
    enter_guest_password("wrong")

    assert_response :unprocessable_entity
  end

  test "the right password lets a guest in" do
    enter_guest_password
    get root_path

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "changing the password locks out old guests" do
    enter_guest_password
    Setting.instance.update!(guest_password: "new-one")
    get root_path

    assert_redirected_to new_guest_access_path
  end

  test "the host gets in without the guest password" do
    sign_in_as_host
    get root_path

    assert_response :success
  end

  test "the host login page skips the guest gate" do
    get new_session_path

    assert_response :success
  end

  test "a full room of guests can all get in" do
    20.times { enter_guest_password }

    assert_redirected_to root_path
  end

  test "older iPhones are let in" do
    get new_guest_access_path, headers: { "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1" }

    assert_response :success
  end

  test "password attempts are rate limited" do
    10.times { enter_guest_password("wrong") }
    enter_guest_password

    assert_redirected_to new_guest_access_path
    assert_equal "Try again later.", flash[:alert]
  end
end

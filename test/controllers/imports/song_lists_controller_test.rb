require "test_helper"

class Imports::SongListsControllerTest < ActionDispatch::IntegrationTest
  test "guests can't import" do
    enter_guest_password
    post imports_song_list_path, params: { file: fixture_file_upload("song_list_excel.csv", "text/csv") }

    assert_redirected_to new_session_path
  end

  test "a file that isn't CSV gets a message, not an error page" do
    sign_in_as_host
    post imports_song_list_path, params: { file: fixture_file_upload("song_list_broken.csv", "text/csv") }

    assert_response :unprocessable_entity
    assert_select ".alert", /couldn't read/i
  end

  test "the host imports a list and sees what happened" do
    sign_in_as_host
    post imports_song_list_path, params: { file: fixture_file_upload("song_list_excel.csv", "text/csv") }

    assert_response :success
    assert_select "li", text: /The Water Is Wide/
  end
end

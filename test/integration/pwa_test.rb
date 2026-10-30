require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "the manifest is public and describes the app" do
    get pwa_manifest_path(format: :json)
    manifest = response.parsed_body

    assert_response :success
    assert_equal [ "Jambook", "standalone", "/" ], manifest.values_at("name", "display", "start_url")
  end

  test "every manifest icon exists" do
    get pwa_manifest_path(format: :json)
    icons = response.parsed_body["icons"]

    assert_equal 3, icons.size
    assert(icons.all? { Rails.public_path.join(it["src"].delete_prefix("/")).exist? })
  end

  test "the service worker is served" do
    get pwa_service_worker_path(format: :js)

    assert_response :success
  end

  test "pages link the manifest" do
    enter_guest_password
    get root_path

    assert_select "link[rel=manifest]"
  end
end

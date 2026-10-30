require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "strangers can't open a cable" do
    assert_reject_connection { connect }
  end

  test "guests can open a cable" do
    cookies.signed[:guest_access] = settings(:one).guest_access_version

    assert_nothing_raised { connect }
  end
end

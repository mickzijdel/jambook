require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")

    assert_equal("downcased@example.com", user.email_address)
  end

  test "a host's email address is unique" do
    refute_predicate User.new(email_address: users(:one).email_address, password: "x"), :valid?
  end

  test "a host needs an email address" do
    refute_predicate User.new(password: "x"), :valid?
  end
end

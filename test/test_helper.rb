ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # turbo-rails includes Turbo::Broadcastable::TestHelper here itself (assert_turbo_stream_broadcasts).
    setup { Rails.cache.clear }
  end
end

Dir[File.expand_path("test_helpers/**/*.rb", __dir__)].each { |file| require file }

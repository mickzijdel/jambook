ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "turbo/broadcastable/test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # turbo-rails would include this only once Action Cable loads, which can be mid-test: the first
    # broadcast then skips the recording adapter. Its recording adapter extends async, so browsers still get it.
    include Turbo::Broadcastable::TestHelper
    setup { Rails.cache.clear }
  end
end

Dir[File.expand_path("test_helpers/**/*.rb", __dir__)].each { |file| require file }

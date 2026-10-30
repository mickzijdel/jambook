# Mark existing migrations as safe
StrongMigrations.start_after = 20261030150549

# Set timeouts for migrations
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour

# Analyze tables after indexes are added
# Outdated statistics can sometimes hurt performance
# auto_analyze calls an adapter method SQLite doesn't have (crashes add_index), so only on other databases.
primary_adapter = ActiveRecord::Base.configurations
  .configs_for(env_name: Rails.env, name: "primary")
  &.adapter.to_s
StrongMigrations.auto_analyze = primary_adapter.present? && !primary_adapter.include?("sqlite")

# Set the version of the production database
# so the right checks are run in development
# StrongMigrations.target_version = 18

# Add custom checks
# StrongMigrations.add_check do |method, args|
#   if method == :add_index && args[0].to_s == "users"
#     stop! "No more indexes on the users table"
#   end
# end

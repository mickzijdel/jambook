require "io/console"

namespace :jambook do
  desc "Create or update the host login: bin/rails jambook:host EMAIL=you@example.com"
  task host: :environment do
    email = ENV.fetch("EMAIL") { abort "Usage: bin/rails jambook:host EMAIL=you@example.com" }
    print "Password for #{email}: "
    password = $stdin.noecho(&:gets).to_s.chomp
    puts
    User.find_or_initialize_by(email_address: email).update!(password: password)
    puts "Saved the host login for #{email}."
  end
end

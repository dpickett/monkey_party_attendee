require "rubygems"
require "test/unit"
require "mocha"
require "activesupport"
require "ruby-debug"
require "pending"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "monkey_party_attendee"

require "support/db/active_record"
require "support/models/user"

ActiveRecord::Base.reset_subclasses
ActiveRecord::Base.clear_reloadable_connections!

# Wait for ActiveRecord to catch up.
sleep 2

# Set up database tables and records
Dir["test/support/db/migrations/*.rb"].each do |file|
  require file.gsub(/\.rb$/, "")
end

require "factory_girl"
require "shoulda"

class Test::Unit::TestCase
end

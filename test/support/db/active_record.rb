require 'yaml'
require 'active_record'

# copied from Pat Allan's thinking sphinx

# Database Defaults
host     = "localhost"
username = "monkey_party"
password = nil

# Read in YAML file
if File.exist?(File.join(File.dirname(__FILE__), "database.yml"))
  config    = YAML.load open(File.join(File.dirname(__FILE__), "database.yml"))
  host      = config["host"]     || host
  username  = config["username"] || username
  password  = config["password"] || password
end

# Set up Connection
ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :database => 'monkey_party',
  :username => username,
  :password => password,
  :host     => host
)

# Copied from ActiveRecord's test suite
ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL = [
    /^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/,
    /^SELECT @@ROWCOUNT/, /^SHOW FIELDS/
  ]

  def execute_with_query_record(sql, name = nil, &block)
    $queries_executed ||= []
    $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
    execute_without_query_record(sql, name, &block)
  end

  alias_method_chain :execute, :query_record
end


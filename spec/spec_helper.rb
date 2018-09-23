
require 'database_cleaner'
require 'rubygems'
require "active_record"
require 'active_support'
require 'sqlite3'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'rails'))
require "init"

require "rails/railtie"

module Rails
  def self.env
    @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development")
  end
end



ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define do

  create_table "users", :force => true do |t|
    t.column "name",       :text
    t.column "account_id", :integer
    t.column "updated_at", :datetime
  end

  create_table "people", :force => true do |t|
    t.column "name",       :text
    t.column "updated_at", :datetime
  end

  create_table "accounts", :force => true do |t|
    t.column "name",       :text
    t.column "updated_at", :datetime
  end

  require_relative '../lib/generators/has_magic_columns/install/templates/migration'
  AddHasMagicColumnsTables.new.change
end


RSpec.configure do |config|

  config.before(:all) do
    class Account < ActiveRecord::Base
      include HasMagicColumns::Extend
      has_many :users
      has_magic_columns
    end

    class Person < ActiveRecord::Base
      include HasMagicColumns::Extend
      has_magic_columns
    end

    class User < ActiveRecord::Base
      include HasMagicColumns::Extend
      belongs_to :account
      has_magic_columns :through => :account
    end
  end

  config.after(:all) do
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
